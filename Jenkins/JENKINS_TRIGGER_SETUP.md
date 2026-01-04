# Jenkins Pipeline Trigger Setup

## Problem: Pipeline Not Starting After Branch Indexing

If Jenkins shows "Finished: SUCCESS" after branch indexing but the pipeline doesn't run, you need to configure build triggers.

## Solution: Configure Build Triggers

### Option 1: Poll SCM (Recommended for Testing)

1. Go to your Jenkins job: `chatapp-infrastructure`
2. Click **Configure**
3. Scroll to **Build Triggers** section
4. Check ✅ **Poll SCM**
5. Enter schedule: `H/5 * * * *` (every 5 minutes)
   - Or `H * * * *` (every hour)
   - Or `@daily` (once per day)
6. Click **Save**

### Option 2: GitHub Webhook (Recommended for Production)

1. **In Jenkins**:
   - Go to **Manage Jenkins** → **Configure System**
   - Find **GitHub** section
   - Add GitHub Server (if not already added)
   - Configure credentials

2. **In Jenkins Job**:
   - Go to your job → **Configure**
   - **Build Triggers** → Check ✅ **GitHub hook trigger for GITScm polling**
   - Click **Save**

3. **In GitHub**:
   - Go to your repository: `https://github.com/tomernos/Observability`
   - **Settings** → **Webhooks** → **Add webhook**
   - **Payload URL**: `http://your-jenkins-url/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Select **Just the push event**
   - Click **Add webhook**

### Option 3: Manual Trigger (For Now)

If you just want to test:

1. Go to your Jenkins job
2. Click **Build Now** (or **Build with Parameters**)
3. Select the branch: `develop` or `main`
4. Click **Build**

## Verify Pipeline Configuration

Make sure your Jenkins job is configured correctly:

1. **Pipeline Definition**: Pipeline script from SCM
2. **SCM**: Git
3. **Repository URL**: `https://github.com/tomernos/Observability.git`
4. **Branches to build**: `*/develop` or `*/main`
5. **Script Path**: `Jenkins/Jenkinsfile.infrastructure` ⚠️ **Important: Check this path!**

## Quick Test

1. **Manual Build**:
   ```
   Jenkins → chatapp-infrastructure → Build Now
   ```

2. **Check Console Output**:
   - Click on the build number
   - Click **Console Output**
   - Verify it's checking out the correct branch and finding the Jenkinsfile

## Common Issues

### Issue: "Jenkinsfile not found"
**Solution**: Check **Script Path** is set to `Jenkins/Jenkinsfile.infrastructure`

### Issue: "Branch not found"
**Solution**: 
- Verify branch exists: `git branch -a`
- Update **Branches to build** to match your branch name

### Issue: Pipeline runs but fails immediately
**Solution**: Check the **Console Output** for specific error messages

## Recommended Setup for Development

For now, use **Poll SCM** with a short interval:

1. **Build Triggers** → ✅ **Poll SCM**
2. **Schedule**: `H/2 * * * *` (every 2 minutes)
3. This will check for changes and trigger builds automatically

## Next Steps

Once the pipeline runs successfully:
1. Remove the frequent polling
2. Set up GitHub webhook for production
3. Configure branch protection rules in GitHub

