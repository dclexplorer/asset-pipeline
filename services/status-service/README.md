# Status Service

A monitoring service for the Godot Server Pipeline that provides health checks and status reporting for all services.

## Features (Planned)

- Health check endpoints for all services
- Service status dashboard
- Metrics collection and reporting
- Alert system for service failures
- Performance monitoring

## API Endpoints (Planned)

- `GET /health` - Service health check
- `GET /status` - Overall system status
- `GET /services` - List of all services and their status
- `GET /services/:service/health` - Specific service health
- `GET /metrics` - System metrics

## Configuration

Environment variables:
- `PORT` - Server port (default: 8082)
- `NODE_ENV` - Environment mode
- `SERVICES_CONFIG` - JSON configuration for monitored services

## Development

```bash
# Install dependencies
npm install

# Run in development mode
npm run dev

# Build
npm run build

# Run production
npm start
```

## Service Configuration

The status service will monitor the following services:
- Consumer Processor (http://consumer-processor:8080/health)
- Entity Queue Producer (http://entity-queue-producer:8081/health)
- CRDT Runner (internal health check)
- Godot Optimizer (internal health check)
- Godot Runner (internal health check)

## Implementation Notes

This service is currently a placeholder. Implementation should include:
1. Service discovery mechanism
2. Health check intervals
3. Status persistence
4. Alert notifications
5. Web dashboard for monitoring