docker build -t fastapi-app .  
docker run -d -p 8000:8000 --name fastapi-container fastapi-app