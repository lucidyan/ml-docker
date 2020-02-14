import argparse
import errno
import os
import shutil

HOME_DIRECTORY = '/home/docker'


def main():
    parser = argparse.ArgumentParser(add_help=True, description='Run docker image.')
    parser.add_argument("--command", "-c", default="jupyter-notebook --ip 0.0.0.0")
    parser.add_argument("--docker_tag", "-t", default='lucidyan/ml-docker:20.02.2',
                        help='Docker image tag')
    parser.add_argument("--port_jupyter", "-pj", default='8888', help='External Jupyter Notebook port')
    parser.add_argument("--port_tensorboard", "-pt", default='6006', help='External Tensorboard port')
    args = parser.parse_args()

    gpu_option = ''
    if shutil.which('nvidia-smi') is not None:
        gpu_option = ' --gpus all'

    run_command = (
        'docker run'
        ' --rm'
        ' -it'
        ' --ipc=host'
        f'{gpu_option}'
        f' -p {args.port_jupyter}:8888 -p {args.port_tensorboard}:6006'
        f' -v {os.getcwd()}/notebooks:{HOME_DIRECTORY}/notebooks'
        f' {args.docker_tag}'
        f' {args.command}'
    )

    print('Running command:\n' + run_command + '\n')
    os.system(run_command)


if __name__ == '__main__':
    main()
