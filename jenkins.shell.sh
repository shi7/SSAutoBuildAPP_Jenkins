
#pro file
configFile='./src/config/config.js'

echo build for ${platform}

gitlog=`git log -n1 --format=format:"%h"`
echo $gitlog

function buildIOS()
{

cd ios && pod install

# ios params
is_workspace="true"
workspace_name="#YOUProjectTargetName"
project_name=""
scheme_name="#YOUProjectTargetName"
build_configuration="Release"
method="ad-hoc"

script_dir="$( cd "$( dirname "$0"  )" && pwd  )"
project_dir=$script_dir

DATE=`date '+%Y%m%d_%H%M%S'`
export_path="$project_dir/build/$scheme_name-$DATE"
export_archive_path="$export_path/$scheme_name.xcarchive"
export_ipa_path="$export_path/"
ipa_name="${scheme_name}_${DATE}"
export_options_plist_path="$project_dir/ExportOptions.plist"


if [ -d "$export_path" ] ; then
    echo $export_path
else
    mkdir -pv $export_path
fi

xcodebuild clean -workspace ${workspace_name}.xcworkspace \
                 -scheme ${scheme_name} \
                 -configuration ${build_configuration}

xcodebuild archive -workspace ${workspace_name}.xcworkspace \
                   -scheme ${scheme_name} \
                   -configuration ${build_configuration} \
                   -archivePath ${export_archive_path}

if [ -d "$export_archive_path" ] ; then
    echo "👀  congratulation you  🚀 🚀 🚀     👀"
else
    echo "👀  build fail 😢 😢 😢  👀"
    exit 1
fi
echo "------------------------------------------------------"

echo " archive ipa ...  👀"

if [ -f "$export_options_plist_path" ] ; then
    rm -f $export_options_plist_path
fi
/usr/libexec/PlistBuddy -c  "Add :method String ${method}"  $export_options_plist_path
/usr/libexec/PlistBuddy -c  "Add :provisioningProfiles:"  $export_options_plist_path
/usr/libexec/PlistBuddy -c  "Add :provisioningProfiles:${bundle_identifier} String ${mobileprovision_name}"  $export_options_plist_path
/usr/libexec/PlistBuddy -c  "Add :compileBitcode Bool false" $export_options_plist_path

cat ${export_options_plist_path}

xcodebuild  -exportArchive \
            -archivePath ${export_archive_path} \
            -exportPath ${export_ipa_path} \
            -exportOptionsPlist ${export_options_plist_path} \
            -allowProvisioningUpdates

if [ -f "$export_ipa_path/$scheme_name.ipa" ] ; then
    echo "👀👀👀 exportArchive ipa succeed 👀👀👀"
    #open $export_path

else
    echo "👀👀👀 exportArchive ipa fail 😢 😢 😢     👀👀👀"
    exit 1
fi

mv $export_ipa_path/$scheme_name.ipa $export_ipa_path/$ipa_name.ipa

if [ -f "$export_ipa_path/$ipa_name.ipa" ] ; then
    echo "👀 export ${ipa_name}.ipa succeed 🎉  🎉  🎉   👀"
else
    echo "👀 export ${ipa_name}.ipa fail 😢 😢 😢     👀"
    exit 1
fi

if [ -f "$export_options_plist_path" ] ; then
    echo "${export_options_plist_path} deleted"
    rm -f $export_options_plist_path
fi
  echo "👀  AutoPackageScript : ${SECONDS}s 👀"
  upload "${export_ipa_path}/${ipa_name}.ipa"
  cd ..  
}

function buildAndroid()
{
  # cd android &&  ./gradlew assembleRelease
  
   cd android  
   rm -fr app/build/
   ./gradlew assembleRelease
   ./gradlew assembleRelease
   cd ..
   # YOU BOUNDLE FILE PATH
   upload "${WORKSPACE}/android/app/build/outputs/apk/release/app-armeabi-v7a-release.apk"
}

function upload()
{
  local filePath=$1
  if [[ $dev_or_product = "develop" ]];then
    #statements
    uploadFirim ${filePath}
  else
    echo filePath = ${filePath}
    ls -a ${export_ipa_path}
    curl -F "file=@${filePath}" -F '_api_key=#YOUKEY' https://www.pgyer.com/apiv2/app/upload
  fi
}

#api
function uploadFirim(){
  local filePath2=$1
  fir p $filePath2 -c "${DATE} build upload,  gitlog = ${gitlog}" -Q -T #YOUPKEY
}

function changeConfig(){
  p='s/0702a/'${gitlog}'/g'
  echo v = $p
  sed -i '' $p ./src/config/config.js
  
  target="ENV = 'develop'"
  value="ENV = 'production'"
  if [[ $dev_or_product = "develop" ]];then
    sed -i '' "s/$value/$target/g" ${configFile}  
    echo 'change develop config ==== ' && cat ${configFile}
  else
    sed -i '' "s/$target/$value/g" ${configFile}  
    echo 'change production config ==== ' && cat ${configFile}
  fi
}

function resetConfig(){
  git checkout ${configFile}
}

#发送钉钉消息
function sendMessage(){
  env=''
  downloadUrl=''
text=""
text="jenkins打包成功"
  if [[ $dev_or_product = "develop" ]];then
      env='测试环境'
      downloadUrl="http://d.firim.pro/#YOUAPPName"
  else
      env='生产环境'
      [[ $1 == *apk* ]] && downloadUrl="https://www.pgyer.com/#YOUAPPName" || downloadUrl="https://www.pgyer.com/#YOUAPPName"
  fi

  title='#YOUAPPName '$dev_or_product$env'更新啦'
  echo $downloadUrl
curl 'https://oapi.dingtalk.com/robot/send?access_token=#YOUTOKEN' \
     -H 'Content-Type: application/json' \
     -d '{
    "msgtype": "actionCard",
    "actionCard": {
        "title": "#YOUAPPName 测试包更新啦",
        "text": "![screenshot](https://#YOUAPPLogo) \n\n #### #YOUAPPName测试包更新啦\n  \n[iOS 下载](http://d.firim.top/#YOUAPPName) \n [android 下载](http://d.firim.top/#YOUAPPName)
        ", 
        "hideAvatar": "0", 
        "btnOrientation": "0", 
        "btns": [
            {
                "title": "iOS 下载", 
                "actionURL": "http://d.firim.top/#YOUAPPName"
            }, 
            {
                "title": "android 下载", 
                "actionURL": "http://d.firim.top/#YOUAPPName"
            }
        ]
    }
}'

}



npm install
changeConfig
if  [[ $platform = "all" ]];then
buildIOS
buildAndroid
elif [[ $platform = "iOS" ]];  then
  buildIOS
elif [[ $platform = "android" ]];  then 
  buildAndroid
fi
resetConfig

if  [[ $needSendMessage = true ]];then
sendMessage
fi
