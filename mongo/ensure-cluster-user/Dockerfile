FROM mongo:4.2

ENV SERVICE_NAME="mongo"
ENV ADMIN_USERNAME="admin"
ENV ADMIN_DB="admin"
ENV MONGO_USERNAME="app"
ENV MONGO_DB="app"
ENV ROLE="read"

# Set working directory
WORKDIR /

# Copy and make script executable in one layer
COPY ensure_user.sh /ensure_user.sh
RUN chmod +x /ensure_user.sh

# Set entrypoint
ENTRYPOINT ["/ensure_user.sh"]
