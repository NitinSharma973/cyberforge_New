# Use an official Ubuntu 20.04 as a base image
FROM ubuntu:latest

# Set environment variables for MySQL root password and new user credentials
ENV MYSQL_ROOT_PASSWORD bug
ENV MYSQL_USER user
ENV MYSQL_PASSWORD pass  

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    sudo \
    apache2 \
    curl \
    wget \
    php \
    libapache2-mod-php \
    php-mysql \
    php-gd \
    mysql-server \
    mysql-client

# Create the directory /nonexistent to avoid 'su' warning
RUN mkdir -p /nonexistent

# Copy bWAPP files
COPY bWAPP /var/www/html/bWAPP

# Set permissions and ownership for directories
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 755 /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql

# Configure MySQL to listen on all interfaces and create the bwapp database and user
RUN sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/mysql.conf.d/mysqld.cnf && \
    service mysql start && \
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE bwapp;" && \
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE USER 'user'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';" && \
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON bwapp.* TO 'user'@'localhost';" && \
    mysqladmin -uroot -p$MYSQL_ROOT_PASSWORD shutdown

# Set ServerName directive to suppress warning message
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Expose port 80
EXPOSE 80

# Start Apache and MySQL services
CMD service apache2 start && service mysql start && tail -f /dev/null
