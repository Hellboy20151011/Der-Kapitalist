# Railway.app Deployment Guide

This guide explains how to deploy the Der-Kapitalist backend to Railway.app.

## Prerequisites

- A Railway.app account (https://railway.app)
- GitHub repository connected to Railway
- PostgreSQL database (can be provisioned on Railway)

## Project Structure

This repository contains:
- **Backend**: Node.js/Express API in `/backend` directory (deployable to Railway)
- **Frontend**: Godot game in root directory (not deployed to Railway)

## Railway Configuration

The project includes Railway-specific configuration files:

### `railway.json`
Specifies build and deploy commands that work from the repository root.

### `nixpacks.toml`
Configures Nixpacks (Railway's build system) to:
- Use Node.js 20
- Install dependencies from the `/backend` directory
- Start the server from the `/backend` directory

## Deployment Steps

### 1. Create a New Project on Railway

1. Go to https://railway.app
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Choose the `Hellboy20151011/Der-Kapitalist` repository
5. Railway will automatically detect the Node.js backend using the configuration files

### 2. Add PostgreSQL Database

1. In your Railway project, click "New"
2. Select "Database" → "Add PostgreSQL"
3. Railway will automatically create a `DATABASE_URL` environment variable

### 3. Configure Environment Variables

Add the following environment variables in Railway:
- `DATABASE_URL` - Automatically provided by Railway PostgreSQL plugin
- `JWT_SECRET` - Generate a secure random string (min 32 characters)
- `JWT_EXPIRES_IN` - Token expiration time (e.g., `7d`)
- `ALLOWED_ORIGINS` - CORS origins (e.g., `https://yourdomain.com`)
- `PORT` - Railway automatically provides this (usually 3000)

**Example values:**
```
JWT_SECRET=your-very-secure-random-string-min-32-chars
JWT_EXPIRES_IN=7d
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

To generate a secure JWT_SECRET, use:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 4. Run Database Migrations

After the first deployment, you need to run database migrations:

**Option A: Using Railway CLI**
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login to Railway
railway login

# Link to your project
railway link

# Connect to database and run migrations
railway run psql $DATABASE_URL -f backend/migrations/001_initial_schema.sql
railway run psql $DATABASE_URL -f backend/migrations/002_add_building_production_columns.sql
railway run psql $DATABASE_URL -f backend/migrations/003_add_performance_indices.sql
```

**Option B: Using Railway Dashboard**
1. Go to your PostgreSQL database in Railway dashboard
2. Click "Data" tab
3. Click "Query"
4. Copy and paste the contents of each migration file and execute them in order

### 5. Deploy

Railway will automatically deploy your application when you push to GitHub.

Your backend will be available at: `https://your-project.up.railway.app`

## WebSocket Configuration

The backend supports WebSocket connections for real-time updates. Railway automatically provides SSL/TLS, so your WebSocket URL will be:

```
wss://your-project.up.railway.app
```

Make sure to configure this in your Godot client's `GameConfig.gd` or environment settings.

## Monitoring

Monitor your application in the Railway dashboard:
- **Logs**: View application logs in real-time
- **Metrics**: CPU, memory, and network usage
- **Deployments**: View deployment history and rollback if needed

## Troubleshooting

### Build Failures

If the build fails with "Error creating build plan with Railpack":
- Ensure `railway.json` and `nixpacks.toml` are in the repository root
- Check that the repository is correctly linked in Railway
- Verify Node.js version compatibility in `backend/package.json`

### Database Connection Issues

If the app can't connect to the database:
- Verify `DATABASE_URL` is set correctly
- Check that migrations have been run
- Ensure PostgreSQL plugin is added to your project

### CORS Errors

If you get CORS errors from the frontend:
- Add your frontend domain to `ALLOWED_ORIGINS`
- Separate multiple origins with commas
- Include both HTTP and HTTPS if needed

### WebSocket Connection Failures

If WebSocket connections fail:
- Use `wss://` (not `ws://`) for production
- Ensure `ALLOWED_ORIGINS` includes your frontend domain
- Check browser console for specific error messages

## Updating the Deployment

To deploy updates:
1. Push changes to GitHub
2. Railway automatically detects changes and redeploys
3. Monitor deployment in Railway dashboard

## Cost Optimization

Railway offers:
- **Free tier**: $5 credit per month
- **Hobby plan**: $5/month for more resources
- **Pro plan**: $20/month for production apps

The backend is lightweight and should run well on the Hobby plan.

## Additional Resources

- [Railway Documentation](https://docs.railway.app/)
- [Railway CLI](https://docs.railway.app/develop/cli)
- [Railway Environment Variables](https://docs.railway.app/develop/variables)
- [Nixpacks Documentation](https://nixpacks.com/)
