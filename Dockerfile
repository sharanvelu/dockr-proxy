FROM ubuntu/nginx:latest

RUN apt-get update && \
    apt-get install -y vim openssl

# Removes default Virtual server conf file
RUN unlink /etc/nginx/sites-enabled/default

# Set default Conf file
COPY default.conf /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Change the default nginx index page to dockr page
COPY site /var/www/default
COPY site/404.html /var/www/404/dt_404.html

# Add add-listener script in bin dir for running the script.
COPY add-listener.sh /usr/local/bin/add-listener
RUN chmod u+x /usr/local/bin/add-listener

EXPOSE 443
EXPOSE 5173
