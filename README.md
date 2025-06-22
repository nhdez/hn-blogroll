# HN Blogroll

![image](https://github.com/nhdez/hn-blogroll/assets/22510253/6dabd6a0-f5fa-400f-b52e-9996ad63b193)

A curated blogroll based on [revskill's](https://news.ycombinator.com/user?id=revskill) Ask HN thread ["Could you share your personal blog here?"](https://news.ycombinator.com/item?id=36575081). This application aggregates personal blogs from HN users and provides a modern interface to discover great content.

## Features

- 🔍 **Smart Discovery**: Browse blogs by author or discover recent posts across all blogs
- 📰 **RSS Integration**: Automatically fetches and stores posts from blog RSS feeds
- 🔄 **Background Processing**: Robust Sidekiq-based job system for data updates
- 🎯 **Advanced Search**: Search through blogs, posts, and content with Ransack
- 📊 **Admin Interface**: Comprehensive admin panel for blog management
- 🚀 **API Support**: RESTful API for blogs and posts
- 📈 **HN Integration**: Tracks HN karma and validates blog status
- 📤 **Multiple Export Formats**: CSV and OPML export capabilities

## Tech Stack

- **Backend**: Rails 7.0.5, Ruby 3.2.1
- **Database**: PostgreSQL (production), SQLite3 (development)
- **Background Jobs**: Sidekiq with Redis
- **Frontend**: Tabler UI with Bootstrap
- **Search**: Ransack with database indexes
- **Caching**: Redis-based caching system
- **RSS Parsing**: Feedjira with duplicate detection

## Installation

### Prerequisites

- Ruby 3.2.1
- Rails 7.0.5
- Redis server
- PostgreSQL (for production)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-repo/hn-blogroll.git
   cd hn-blogroll
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Setup database**
   ```bash
   rails db:create
   rails db:migrate
   ```

4. **Start Redis server**
   ```bash
   redis-server
   ```

5. **Start Sidekiq worker (in separate terminal)**
   ```bash
   bundle exec sidekiq
   ```

6. **Start the Rails server**
   ```bash
   rails server
   ```

7. **Visit the application**
   - Main site: http://localhost:3000
   - Sidekiq monitor: http://localhost:3000/sidekiq
   - Admin interface: http://localhost:3000/admin

## Usage

### Manual Data Updates

Use the provided Rake tasks to manually trigger updates:

```bash
# Fetch new blogs from HN thread
rake blogroll:fetch_hn_data

# Update all blog posts from RSS feeds
rake blogroll:update_posts

# Update specific blog posts
rake blogroll:update_blog_posts[blog_id]

# Update HN karma for all users
rake blogroll:update_karma

# Check online status of all blogs
rake blogroll:check_status

# Run all updates
rake blogroll:full_update
```

### Scheduled Jobs

The application automatically runs scheduled jobs:

- **Every 6 hours**: Fetch new blogs from HN thread
- **Daily at 2 AM**: Update all blog posts from RSS feeds
- **Weekly on Sunday at 4 AM**: Update HN karma for all users
- **Weekly on Monday at 6 AM**: Check blog online status

### API Endpoints

#### Blogs API
- `GET /api/v1/blogs` - List all approved blogs
- `GET /api/v1/blogs/:id` - Get specific blog with posts
- `GET /api/v1/blogs/:id/posts` - Get posts for specific blog

#### Posts API
- `GET /api/v1/posts` - List all posts from approved blogs
- `GET /api/v1/posts/:id` - Get specific post

#### Query Parameters
- `page` - Page number for pagination
- `per_page` - Items per page (default: 20)
- `q[field_name_cont]` - Search within field (Ransack syntax)

Example API calls:
```bash
# Get recent posts
curl http://localhost:3000/api/v1/posts

# Search for posts containing "rails"
curl "http://localhost:3000/api/v1/posts?q[title_or_content_cont]=rails"

# Get blogs with pagination
curl "http://localhost:3000/api/v1/blogs?page=2&per_page=10"
```

### Admin Interface

Access the admin interface at `/admin` to:

- Approve/reject submitted blogs
- Manually refresh posts for specific blogs
- Check blog status and update karma
- View comprehensive statistics
- Manage posts (view and delete if needed)

**Security**: The admin interface is protected by Devise authentication. Create your first admin user using the rake task:

```bash
# Create admin user (uses ADMIN_EMAIL and ADMIN_PASSWORD env vars)
rake admin:create

# Or create with custom credentials
ADMIN_EMAIL=admin@yourdomain.com ADMIN_PASSWORD=yourpassword rake admin:create

# List all admin users
rake admin:list
```

## Configuration

### Environment Variables

For production deployment, set these environment variables:

```bash
# Database (PostgreSQL for production)
DATABASE_HOST=localhost
DATABASE_NAME=hn_blogroll_production
DATABASE_USERNAME=your_db_user
DATABASE_PASSWORD=your_db_password

# Redis
REDIS_URL=redis://localhost:6379/0

# Rails
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key_base

# Admin User Creation (for first setup)
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=your_secure_password
```

### Background Jobs

The application uses Sidekiq for background processing. Jobs are scheduled using sidekiq-cron and configured in `config/sidekiq_schedule.yml`.

Monitor job performance and status at `/sidekiq`.

## Development

### Architecture

The application follows Rails conventions with these key components:

- **Models**: `Blog` and `Post` with proper associations and validations
- **Jobs**: Sidekiq jobs for data fetching and processing
- **Services**: Business logic encapsulated in service classes
- **Controllers**: Separate namespaces for main site, admin, and API
- **Background Processing**: Scheduled jobs with error handling and logging

### Key Services

- `HackerNewsParser`: Parses HN thread for new blog submissions
- `RssFeedParser`: Fetches and processes RSS feeds with duplicate detection
- `KarmaUpdater`: Updates HN karma using HN API
- `BlogStatusChecker`: Validates blog accessibility

### Error Handling

The application includes comprehensive error handling:
- Graceful failures with logging
- Retry mechanisms for transient errors
- Status tracking for blogs and posts
- Detailed error reporting in jobs

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For questions, suggestions, or issues:
- Create an issue on GitHub
- Contact: nelson@datapolaris.com

---

*The stack: Rails 7 + Tabler UI + Sidekiq + Redis + PostgreSQL*
