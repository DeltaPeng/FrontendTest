# the prod version, multi-step build process so we can drop the node-modules dependencies 150+MB from the final image

# step1 builder phase
# docker image to build from
FROM node:alpine as builderPhase

# change default working dir. Will create any folders that don't exist.
# WORKDIR /usr/app   Some may prefer putting it in var or in home dir
# makes this the default dir all commands run from
WORKDIR /app

# command to copy files from (path on file system) to (path on container)
# copies all files from current working dir, to current working dir (default location: root) inside container
COPY ./package.json ./ 

# additional items to run 
# call npm to install dependencies of package.json
RUN npm install

#separated this copy so that, if a regular change occurs to non-package.json, 
# the cached version of the images up to this step can be run instead
# and the lengthy npm install can be skipped when unneeded
COPY ./ ./ 
 
# change default command, build the output of the project, to be copied to another container in next step
# CMD ["npm", "run", "build"]
RUN npm run build


# step 2, auto delims for each FROM
# use NGINX as prod server, as we DON'T want the alpine dev server in prod
# copy the output from phase1 to the appropriate location in prod server
# And from there, nginx's default command starts it up so no tinkering needed
FROM nginx

# only used by AWS, to let it know which port we are opening data on
EXPOSE 80

COPY --from=builderPhase /app/build /usr/share/nginx/html
 


# then run it like so. If no tag is specified, default is latest
#   docker build -t tngai13/frontend-prod .
# this container requires incoming traffic into it (when user types in url)
# set it up so when user types url, it connects to container to get output
#
# In browser, can't use localhost for docker toolbar, i.e.: http://192.168.99.100:3001/
# Note that nginx's default port is 80. 
# No need to mount drives since it's production, we don't plan to change code. 
# Saved about 200MB by removing dependencies / node_modules from this prod build
#   docker run -p 3001:80 tngai13/frontend-prod