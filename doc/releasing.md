# How to package up a GoodCity Release

It is important to follow the procedure below so that we maintain consistent release tagging. This will help with troubleshooting future bugs based on platform and app versions.

## Building and releasing steps

Perform the following commands on each repository: shared.goodcity, app.goodcity, admin.goodcity, api.goodcity, socket.goodcity, stockit.goodcity

Notes
* ensure you have a clean git folder before beginning. If not, stash the changes using `git stash save`
* begin with shared.goodcity first as these need to be committed and pushed before app.goodcity and admin.goodcity builds begin.


For app.goodcity and admin.goodcity you must also bump the version number in `cordova/appDetails.json`. Do this for both staging and live environments. Given the following json file, you would increment to 0.7.0 in both cases.

```json
{
  "staging": {
    "name": "S. GoodCity",
    "url": "hk.goodcity.appstaging",
    "version": "0.6.21",
    "signing_detail": "iPhone Distribution: Crossroads Foundation Limited (6B8FS8W94M)"
  },
  "production": {
    "name": "GoodCity",
    "url": "hk.goodcity.app",
    "version": "0.6.1",
    "signing_detail": "iPhone Distribution: Crossroads Foundation Limited (6B8FS8W94M)"
  }
}
```

Commit the version change

    git add cordova/appDetails.json
    git commit -m "Bump version"

Merge the code to the live branch.

    git checkout master
    git pull --rebase origin master
    git push origin master
    git checkout live
    git pull --rebase origin live
    git merge master
    git push origin live

For admin.goodcity, app.goodcity and shared.goodcity you must tag the release with the same tag as the app version. Note: you must add a 0.0.1 increment to the tag name as when the CircleCI builds run, they increment the version number before building the apps. For example, if we set `appDetails.json` to version `0.7.0`, then use the git tag `0.7.1` as this will be the mobile app version that is generated.

    git tag 0.7.1
    git push origin 0.7.1

CircleCI will now begin the test and deploy process. Watch the builds to ensure that the code is deployed.

## Buidling and distributing the mobile apps

Once completed CircleCI will upload the admin.goodcity and app.goodcity Android apps to the Testfairy service. Download and test the builds.

If you are satisfied the apps are working correctly, upload them to the Google Play store and submit for distribution.

Build the iOS apps from the `live` branch and test them. Upload to iOS for submission when complete.
