import argparse
import os

HOME_DIRECTORY = '/home/docker'


def main():
    parser = argparse.ArgumentParser(add_help=True, description='Run docker image.')
    parser.add_argument("--command", "-c", default="jupyter-notebook --ip 0.0.0.0")
    parser.add_argument("--docker_tag", "-t", default='lucidyan/ml-docker:1.3',
                        help='Docker image tag')
    parser.add_argument("--port_jupyter", "-pj", default='8888', help='External Jupyter Notebook port')
    parser.add_argument("--port_tensorboard", "-pt", default='6006', help='External Tensorboard port')
    args = parser.parse_args()

    run_command = ('nvidia-docker run --rm -it '
                   '-p {1}:8888 -p {2}:6006 '
                   '-v {0}/dev_toolkit:{5}/dev_toolkit '
                   '{3} '
                   '{4} '
        .format(
            os.getcwd(),
            args.port_jupyter,
            args.port_tensorboard,
            args.docker_tag,
            args.command,
            HOME_DIRECTORY
        )
    )

    print('Running command:\n' + run_command + '\n')
    os.system(run_command)


if __name__ == '__main__':
    main()
