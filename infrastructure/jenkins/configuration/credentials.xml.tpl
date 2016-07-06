<?xml version='1.0' encoding='UTF-8'?>
<com.cloudbees.plugins.credentials.SystemCredentialsProvider plugin="credentials@1.24">
  <domainCredentialsMap class="hudson.util.CopyOnWriteMap$Hash">
    <entry>
      <com.cloudbees.plugins.credentials.domains.Domain>
        <specifications/>
      </com.cloudbees.plugins.credentials.domains.Domain>
      <java.util.concurrent.CopyOnWriteArrayList>
        <org.csanchez.jenkins.plugins.kubernetes.ServiceAccountCredential plugin="kubernetes@0.6">
          <scope>GLOBAL</scope>
          <id>1a12dfa4-7fc5-47a7-aa17-cc56572a41c7</id>
          <description></description>
        </org.csanchez.jenkins.plugins.kubernetes.ServiceAccountCredential>
        <com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
          <scope>GLOBAL</scope>
          <id>bdd-kieserver</id>
          <description></description>
          <username>kieserver</username>
          <password>bdddemo1!</password>
        </com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
      </java.util.concurrent.CopyOnWriteArrayList>
    </entry>
  </domainCredentialsMap>
</com.cloudbees.plugins.credentials.SystemCredentialsProvider>
