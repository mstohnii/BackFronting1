# Full Stack Docker Application 🚀

A simple, containerized full-stack application with React frontend and Node.js backend, designed for easy deployment with Docker and AWS CloudFront.

## Features

- **Frontend**: React with Vite, modern UI with gradient backgrounds
- **Backend**: Node.js with Express, RESTful API
- **Containerization**: Docker with multi-stage builds
- **Proxy**: Nginx for serving frontend and proxying API calls
- **Cloud Ready**: CloudFront configuration for AWS deployment

## Quick Start

### Local Development

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

The application will be available at:
- Frontend: http://localhost
- Backend API: http://localhost/api/health

### Production Deployment

```bash
# Use production configuration
docker-compose -f deploy/docker-compose.prod.yml up -d
```

## Application Structure

```
.
├── backend/                 # Node.js API server
│   ├── server.js           # Express server with API endpoints
│   ├── package.json        # Backend dependencies
│   └── Dockerfile          # Backend container config
├── frontend/               # React application
│   ├── src/
│   │   ├── App.jsx        # Main React component
│   │   ├── App.css        # Styling
│   │   └── main.jsx       # React entry point
│   ├── index.html         # HTML template
│   ├── package.json       # Frontend dependencies
│   ├── Dockerfile         # Frontend container config
│   └── nginx.conf         # Nginx configuration
├── cloudformation/        # AWS deployment templates
├── deploy/               # Production deployment configs
└── docker-compose.yml    # Local development setup
```

## API Endpoints

- `GET /api/health` - Backend health check
- `GET /api/items` - Get all items
- `GET /api/items/:id` - Get specific item
- `POST /api/items` - Create new item

## Frontend Features

- **Modern UI**: Gradient backgrounds, glassmorphism effects
- **Responsive Design**: Mobile-friendly layout
- **Real-time Communication**: Axios-based API integration
- **Health Monitoring**: Backend status indicator
- **Interactive Forms**: Add new items dynamically

## Docker Services

### Backend Service
- **Port**: 3000 (internal)
- **Health Check**: `/api/health` endpoint
- **Restart Policy**: unless-stopped

### Frontend Service
- **Port**: 80 (external)
- **Features**: Nginx proxy, static file serving
- **API Proxy**: Routes `/api/*` to backend service

## AWS Deployment

See [AWS Deployment Guide](deploy/aws-deployment.md) for detailed instructions on deploying to AWS with CloudFront.

### CloudFront Features
- **CDN**: Global content delivery
- **SSL/TLS**: HTTPS redirect and modern protocols
- **Caching**: Optimized for static assets, disabled for API
- **SPA Support**: Proper handling of client-side routing

## Development

### Adding New Features

1. **Backend**: Add routes in `backend/server.js`
2. **Frontend**: Update components in `frontend/src/`
3. **Rebuild**: `docker-compose up --build`

### Environment Variables

Backend supports:
- `NODE_ENV`: Environment (development/production)
- `PORT`: Server port (default: 3000)

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure port 80 is available
2. **Build failures**: Check Docker logs with `docker-compose logs`
3. **API connectivity**: Verify nginx proxy configuration

### Health Checks

```bash
# Check backend health
curl http://localhost/api/health

# Check frontend
curl http://localhost

# View container status
docker-compose ps
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with Docker
5. Submit a pull request

## License

MIT License - feel free to use this project as a starting point for your own applications!
