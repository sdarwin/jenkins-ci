## Documentation and Website Previews for The C++ Alliance  
  
### User Guide
  
This section covers what end-users should know about the preview generation on https://github.com/cppalliance/cppalliance.github.io and other github repositories.  
  
When a modification is made to the website, usually a pull request is submitted here: https://github.com/cppalliance/cppalliance.github.io/pulls   
  
A bot will automatically post a comment to the new PR conversation, such as:  
  
"An automated preview of this PR is available at http://60.cppalliance.prtest.cppalliance.org"  
  
The user can click on the link, and view their proposed changes. Any new commits will regenerate the preview, and the bot will re-post the preview link.  
  
Finally, the repository admin may accept the pull request, and merge it into the develop branch.  
  
That's all you need to know in order to use the preview functionality. Submit a pull request, and keep a look out for the preview link.  
  
Many cppalliance (and boost) repositories that contain documentation have been configured, including:    
    
Beast https://github.com/boostorg/beast    
JSON https://github.com/boostorg/json  
Unordered https://github.com/boostorg/unordered

'develop' and 'master' branch documentation will be generated for non-boost libraries. For example, if the repository is 'crypt'.  
https://develop.crypt.cpp.al  
https://master.crypt.cpp.al  

More information: behind the scenes, this is accomplished [with Jenkins.](jenkins-summary.md)    

