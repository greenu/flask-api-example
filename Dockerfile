FROM python:3.7-slim

# put nginx in base image
RUN apt-get clean \
    && apt-get -y update

RUN apt-get -y install \
    nginx \
    python3-dev \
    build-essential

COPY deploy/nginx.conf /etc/nginx/nginx.conf
COPY deploy/uwsgi.ini deploy/start.sh /app/
COPY ./requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip install -r requirements.txt
COPY flask_api /app/flask_api/

EXPOSE 80

RUN chmod +x ./start.sh
CMD ["./start.sh"]