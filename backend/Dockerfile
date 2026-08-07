# Build context is backend/ (see render.yaml dockerContext).

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore against the project files alone so the (slow) restore layer is only
# invalidated when a .csproj changes, not on every source edit. Tests are not
# copied — they aren't part of the runtime image.
COPY src/Bit2sky.Domain/Bit2sky.Domain.csproj           src/Bit2sky.Domain/
COPY src/Bit2sky.Shared/Bit2sky.Shared.csproj           src/Bit2sky.Shared/
COPY src/Bit2sky.Application/Bit2sky.Application.csproj src/Bit2sky.Application/
COPY src/Bit2sky.Infrastructure/Bit2sky.Infrastructure.csproj src/Bit2sky.Infrastructure/
COPY src/Bit2sky.API/Bit2sky.API.csproj                 src/Bit2sky.API/
RUN dotnet restore src/Bit2sky.API/Bit2sky.API.csproj

COPY src/ src/
RUN dotnet publish src/Bit2sky.API/Bit2sky.API.csproj \
    -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app .

# Render routes to the port named by $PORT; 8080 is set on both sides so the
# health check and the listener agree. Bind 0.0.0.0 — the container's loopback
# is not reachable from Render's proxy.
ENV ASPNETCORE_HTTP_PORTS=8080 \
    ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080

# Drop root. APP_UID is defined by the aspnet base image.
USER $APP_UID

ENTRYPOINT ["dotnet", "Bit2sky.API.dll"]
