plan(key:'HTTPCHEC',name:'http-checks',description:'HTTP checks for Bamboo Servers') {
   project(key:'OTHERS',name:'Other Buildeng plans')
   repository(name:'http-checks')
   trigger(type:'polling',strategy:'periodically',frequency:'180') {
      repository(name:'http-checks')
   }
   stage(name:'Default Stage') {
      job(key:'JOB1',name:'Default Job') {
         artifactDefinition(name:'image',pattern:'image.tar.gz',shared:'true')
         miscellaneousConfiguration() {
            pbc(enabled:'true',image:'docker.atlassian.io/buildeng/agent-baseagent',
               size:'small') {
               extraContainer(name:'docker',image:'docker:stable-dind',size:'regular')
            }
         }
         task(type:'checkout',description:'Checkout Default Repository') {
            repository(name:'http-checks')
         }
         task(type:'script',description:'Build docker image',
            script:'bin/build.sh',interpreter:'RUN_AS_EXECUTABLE')
         task(type:'script',description:'Save docker image',
            script:'bin/save.sh',interpreter:'RUN_AS_EXECUTABLE')
      }
   }
   branchMonitoring() {
      createBranch()
      inactiveBranchCleanup(periodInDays:'30')
      deletedBranchCleanup(periodInDays:'7')
   }
   dependencies(triggerForBranches:'true')
}

deployment(name:'http-checks deployment',planKey:'OTHERS-HTTPCHEC',
   description:'deploy http-checks docker image') {
   versioning(version:'release-2',autoIncrementNumber:'true')
   environment(name:'Docker registry') {
      task(type:'cleanWorkingDirectory')
      task(type:'artifactDownload',description:'Download release contents',
         planKey:'OTHERS-HTTPCHEC') {
         artifact(name:'image',localPath:'.')
      }
      task(type:'script',description:'Push to registry',
         script:'bin/push.sh',interpreter:'RUN_AS_EXECUTABLE')
      task(type:'pbc',image:'docker.atlassian.io/buildeng/agent-baseagent',
         size:'small') {
         extraContainer(name:'docker',image:'docker:stable-dind',size:'regular')
      }
      permissions() {
         user(name:'obrent',permissions:'read,write,build')
         anonymous(permissions:'read')
         loggedInUser(permissions:'read')
      }
   }
}
