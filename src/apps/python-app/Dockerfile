FROM python:3.12-slim

WORKDIR /app
ENV PYTHONUNBUFFERED=1
COPY . .

RUN pip install flask requests
EXPOSE 5000
CMD ["python", "-u", "app.py"]
