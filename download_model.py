#!/usr/bin/env python3

import argparse
import base64
import datetime
import hashlib
import json
import re
import sys
from pathlib import Path

import requests
import tqdm
from tqdm.contrib.concurrent import thread_map
from huggingface_hub.hf_api import HfFolder; import os; HfFolder.save_token(os.environ['HF_TOKEN'])

def sanitize_model_and_branch_names(model, branch):
    if model[-1] == '/':
        model = model[:-1]
    if branch is None:
        branch = "main"
    else:
        pattern = re.compile(r"^[a-zA-Z0-9._-]+$")
        if not pattern.match(branch):
            raise ValueError("Invalid branch name. Only alphanumeric characters, period, underscore and dash are allowed.")

    return model, branch

def get_download_links_from_huggingface(model, branch, text_only=False):
    base = "https://huggingface.co"
    page = f"/api/models/{model}/tree/{branch}"
    cursor = b""

    links = []
    sha256 = []
    classifications = []
    has_pytorch = False
    has_pt = False
    has_ggml = False
    has_safetensors = False
    is_lora = False
    while True:
        url = f"{base}{page}" + (f"?cursor={cursor.decode()}" if cursor else "")
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        content = r.content

        dict = json.loads(content)
        if len(dict) == 0:
            break

        for i in range(len(dict)):
            fname = dict[i]['path']
            if not is_lora and fname.endswith(('adapter_config.json', 'adapter_model.bin')):
                is_lora = True

            is_pytorch = re.match("(pytorch|adapter)_model.*\.bin", fname)
            is_safetensors = re.match(".*\.safetensors", fname)
            is_pt = re.match(".*\.pt", fname)
            is_ggml = re.match(".*ggml.*\.bin", fname)
            is_tokenizer = re.match("(tokenizer|ice).*\.model", fname)
            is_text = re.match(".*\.(txt|json|py|md)", fname) or is_tokenizer

            if any((is_pytorch, is_safetensors, is_pt, is_ggml, is_tokenizer, is_text)):
                if 'lfs' in dict[i]:
                    sha256.append([fname, dict[i]['lfs']['oid']])
                if is_text:
                    links.append(f"https://huggingface.co/{model}/resolve/{branch}/{fname}")
                    classifications.append('text')
                    continue
                if not text_only:
                    links.append(f"https://huggingface.co/{model}/resolve/{branch}/{fname}")
                    if is_safetensors:
                        has_safetensors = True
                        classifications.append('safetensors')
                    elif is_pytorch:
                        has_pytorch = True
                        classifications.append('pytorch')
                    elif is_pt:
                        has_pt = True
                        classifications.append('pt')
                    elif is_ggml:
                        has_ggml = True
                        classifications.append('ggml')

        cursor = base64.b64encode(f'{{"file_name":"{dict[-1]["path"]}"}}'.encode()) + b':50'
        cursor = base64.b64encode(cursor)
        cursor = cursor.replace(b'=', b'%3D')

    # If both pytorch and safetensors are available, download safetensors only
    if (has_pytorch or has_pt) and has_safetensors:
        for i in range(len(classifications) - 1, -1, -1):
            if classifications[i] in ['pytorch', 'pt']:
                links.pop(i)

    return links, sha256, is_lora


def get_output_folder(model, branch, is_lora, base_folder=None):
    if base_folder is None:
        base_folder = 'models' if not is_lora else 'loras'

    output_folder = Path(base_folder)
    return output_folder


def get_single_file(url, output_folder, start_from_scratch=False):
    filename = Path(url.rsplit('/', 1)[1])
    output_path = output_folder / filename
    if output_path.exists() and not start_from_scratch:
        # Check if the file has already been downloaded completely
        r = requests.get(url, stream=True, timeout=10)
        total_size = int(r.headers.get('content-length', 0))
        if output_path.stat().st_size >= total_size:
            return
        # Otherwise, resume the download from where it left off
        headers = {'Range': f'bytes={output_path.stat().st_size}-'}
        mode = 'ab'
    else:
        headers = {}
        mode = 'wb'

    r = requests.get(url, stream=True, headers=headers, timeout=10)
    with open(output_path, mode) as f:
        total_size = int(r.headers.get('content-length', 0))
        block_size = 1024
        with tqdm.tqdm(total=total_size, unit='iB', unit_scale=True, bar_format='{l_bar}{bar}| {n_fmt:6}/{total_fmt:6} {rate_fmt:6}') as t:
            for data in r.iter_content(block_size):
                t.update(len(data))
                f.write(data)


def start_download_threads(file_list, output_folder, start_from_scratch=False, threads=1):
    thread_map(lambda url: get_single_file(url, output_folder, start_from_scratch=start_from_scratch), file_list, max_workers=threads, disable=True)


def download_model_files(model, branch, links, sha256, output_folder, start_from_scratch=False, threads=1):
    # Creating the folder and writing the metadata
    if not output_folder.exists():
        output_folder.mkdir()
    with open(output_folder / 'huggingface-metadata.txt', 'w') as f:
        f.write(f'url: https://huggingface.co/{model}\n')
        f.write(f'branch: {branch}\n')
        f.write(f'download date: {str(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))}\n')
        sha256_str = ''
        for i in range(len(sha256)):
            sha256_str += f'    {sha256[i][1]} {sha256[i][0]}\n'
        if sha256_str != '':
            f.write(f'sha256sum:\n{sha256_str}')

    # Downloading the files
    print(f"Downloading the model to {output_folder}")
    start_download_threads(links, output_folder, start_from_scratch=start_from_scratch, threads=threads)


def check_model_files(model, branch, links, sha256, output_folder):
    # Validate the checksums
    validated = True
    for i in range(len(sha256)):
        fpath = (output_folder / sha256[i][0])

        if not fpath.exists():
            print(f"The following file is missing: {fpath}")
            validated = False
            continue

        with open(output_folder / sha256[i][0], "rb") as f:
            bytes = f.read()
            file_hash = hashlib.sha256(bytes).hexdigest()
            if file_hash != sha256[i][1]:
                print(f'Checksum failed: {sha256[i][0]}  {sha256[i][1]}')
                validated = False
            else:
                print(f'Checksum validated: {sha256[i][0]}  {sha256[i][1]}')

    if validated:
        print('[+] Validated checksums of all model files!')
    else:
        print('[-] Invalid checksums. Rerun download-model.py with the --clean flag.')

def download_model(model, base_folder, branch="main", threads=1, text_only=False, check=False):
    # Cleaning up the model/branch names
    try:
        model, branch = sanitize_model_and_branch_names(model, branch)
    except ValueError as err_branch:
        print(f"Error: {err_branch}")
        sys.exit()

    # Getting the download links from Hugging Face
    links, sha256, is_lora = get_download_links_from_huggingface(model, branch, text_only=text_only)

    # Getting the output folder
    output_folder = get_output_folder(model, branch, is_lora, base_folder)

    if check:
        # Check previously downloaded files
        check_model_files(model, branch, links, sha256, output_folder)
    else:
        # Download files
        download_model_files(model, branch, links, sha256, output_folder, threads=threads)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('model', type=str, default=None, nargs='?')
    parser.add_argument('--branch', type=str, default='main', help='Name of the Git branch to download from.')
    parser.add_argument('--threads', type=int, default=1, help='Number of files to download simultaneously.')
    parser.add_argument('--text-only', action='store_true', help='Only download text files (txt/json).')
    parser.add_argument('--output', type=str, default=None, help='The folder where the model should be saved.')
    parser.add_argument('--clean', action='store_true', help='Does not resume the previous download.')
    parser.add_argument('--check', action='store_true', help='Validates the checksums of model files.')
    args = parser.parse_args()
    
    download_model(model=args.model, base_folder=args.output, branch=args.branch,
                   threads=args.threads, text_only=args.text_only, check=args.check)
