#!/usr/bin/env python3

import os
import argparse


def main():
    parser = argparse.ArgumentParser(add_help=True, description='Run docker image.')
    parser.add_argument("--docker_tag", "-t", default='lucidyan/ml-docker:1.2', help='Docker image tag')
    args = parser.parse_args()

    run_command = 'nvidia-docker run --rm -it -p 8888:8888 -v {0}:/notebooks -w /notebooks {1}'.format(
        os.getcwd(), args.docker_tag)

    print('Running command\n' + run_command)
    os.system(run_command)


if __name__ == '__main__':
    main()
