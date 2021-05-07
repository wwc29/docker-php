# Docker-PHP

## Using
docker run -p 80:80 /webroot:/var/www/html islenbo/php

## Logs
### Nginx log
path: /var/log/nginx

example: docker run -v ${PWD}/logs/nginx:/var/log/nginx islenbo/php

### PHP-FPM slow log
path: /var/log/php/*-slow.log

example: docker run -v ${PWD}/logs/php:/var/log/php --cap-add=sys_ptrace islenbo/php

#### sys_ptrace 说明
在Linux系统中，PHP-FPM使用SYS_PTRACE跟踪worker进程，但是docker容器默认不启用，如果想让慢日志生效，必须开启`sys_ptrace`
