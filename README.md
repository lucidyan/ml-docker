Build the container:

`docker build -t "lucidyan/ml-docker:1.2" .`

Run it

`python3 run_docker_jupyter.py`

or

`nvidia-docker run --rm -it -p 8888:8888 -v $(pwd):/notebooks -w /notebooks "lucidyan/ml-docker:1.2"`
