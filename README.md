# Builder
provides a recipe for installing and configuring the habitat builder

Prerequisites
============

Create a bitbucket account and then follow these instructions for creating an oauth consumer
https://confluence.atlassian.com/bitbucket/oauth-on-bitbucket-cloud-238027431.html

name the oauth consumer builder. the consumer will only need the repository read permissions and nothing else. put the callback url as
http://kitchen-builder.test.com:8081/
and the url as:
http://kitchen-builder.test.com:8081
Tick the box that says `This is a private consumer` 
Once created make a note of the oauth id and secret.
In the root directory of the cookbook copy the .kitchen.example.yml file to .kitchen.yml and alter as suggested by the comments:
```
    attributes:
      builder:
        create_user_and_group: true
        internal_repo: :  # A URL to the server that has all the artifacts needed
#        origin:
#          core:
#            access_token: <when you have created the core origin and the hab access token put the token string here>
        oauth:
          provider: bitbucket # keep this as bitbucket for now
          client_id:  # create a bitbucket account then create an oauth consumer to get the client id
          client_secret: # create a bitbucket account then create an oauth consumer to get the client secret
          userinfo_url: https://api.bitbucket.org/1.0/user
          authorize_url: https://bitbucket.org/site/oauth2/authorize
          token_url: https://bitbucket.org/site/oauth2/access_token
          builder_url: http://kitchen-builder.test.com:8081 # this is arbitrary but must match the url setting in the oauth consumer - also 8081 is the default port used for the builder by this cookbook 
          redirect_url: http://kitchen-builder.test.com:8081/ # this is arbitrary but must match the callback_url setting in the oauth consumer
```
Leave the origin parts commented for now. There is currently a manual step needed to generate the core origin and access token. Also set up the driver settings for your AWS account in the .kitchen.yml file.

Useage
======

After setting up the kitchen.yml and creating the bitbucket oauth consumer its time to test:
 * run kitchen converge once to setup the builder
 * retrive the public ip address of the instance for ec2
 * make an entry in your hosts file for `<public-ipaddress> kitchen-builder.test.com`
 * Browse to http://kitchen-builder.test.com:8081 and manually create the core origin and the hab access token (make a note of the access token string)
 * populate the attribute origin -> core -> access_token in the kitchen.yml with the string from the builder UI
 * re run kitchen converge

after this the builder will be fully setup.
