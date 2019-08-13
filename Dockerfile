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
WORKDIR /app
COPY app /app/
RUN pip install -r requirements.txt

EXPOSE 80

RUN chmod +x ./start.sh
CMD ["./start.sh"]