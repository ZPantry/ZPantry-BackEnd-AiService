FROM mcr.microsoft.com/dotnet/sdk:10.0 AS backend-build
WORKDIR /src

# Restore first so dependency layers can be cached.
COPY ZPantry-Backend/AuthenticationModule/AuthenticationModule.csproj ZPantry-Backend/AuthenticationModule/
COPY ZPantry-Backend/ZPantryModule/ZPantryModule.csproj ZPantry-Backend/ZPantryModule/
COPY ZPantry-Backend/ZPantry_Backend/ZPantry_Backend.csproj ZPantry-Backend/ZPantry_Backend/

RUN dotnet restore ZPantry-Backend/ZPantry_Backend/ZPantry_Backend.csproj

# Publish the backend into a self-contained folder for the runtime image.
COPY . .
RUN dotnet publish ZPantry-Backend/ZPantry_Backend/ZPantry_Backend.csproj -c Release -o /app/backend /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

ENV ASPNETCORE_URLS=http://+:8080
ENV AI_SERVICE_URL=http://127.0.0.1:8000

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-venv python3-pip bash ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=backend-build /app/backend ./backend
COPY ZPantry-AIService/requirements.txt ./ai-service/requirements.txt
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"
RUN pip install --no-cache-dir -r ./ai-service/requirements.txt

COPY ZPantry-AIService ./ai-service
COPY start-services.sh ./start-services.sh
RUN chmod +x ./start-services.sh

EXPOSE 8080 8000

ENTRYPOINT ["./start-services.sh"]
