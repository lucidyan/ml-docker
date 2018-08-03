#!/usr/bin/env python3

import os
import argparse


def main():
    parser = argparse.ArgumentParser(add_help=True, description='Run docker image.')
    parser.add_argument("--docker_tag", "-t", default='lucidyan/ml-docker:1.3', help='Docker image tag')
    parser.add_argument("--port_jupyter", "-pj", default='8888', help='External Jupyter Notebook port')
    parser.add_argument("--port_tensorboard", "-pt", default='6006', help='External Tensorboard port')
    args = parser.parse_args()

    run_command = 'nvidia-docker run --rm -it -p {2}:8888 -p {3}:6006 -v {0}:/notebooks -w /notebooks {1}'.format(
        os.getcwd(),
        args.docker_tag,
        args.port_jupyter,
        args.port_tensorboard,
    )

    print('Running command\n' + run_command)
    os.system(run_command)


if __name__ == '__main__':
    main()
