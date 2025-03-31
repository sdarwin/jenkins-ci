
## Jenkins CI Jobs

The repository contains the Jenkinfiles used to build documentation previews for Boost and The C++ Alliance.  

In addition to doc previews there may also be benchmarking automation and other types of CI jobs.

See the [jenkinsfiles](jenkinsfiles) directory for file content.   

The [scripts](scripts) directory will have scripts used by the jobs. prebuild, postbuild.  

The [docs](docs) directory will cover more information about how the server was installed and about specific target repositories and jobs. 

To request docs previews on your repository, open an Issue here in cppalliance/jenkins-ci. Keep in mind, previews depend on a doc/ folder being present and that some version of docs should be buildable even if they are still in an initial state.  
