FROM --platform=linux/amd64 python:3.8-slim
WORKDIR /app
COPY . /app
RUN pip install Flask
EXPOSE 5000
CMD ["python", "app.py"]

