#工程名称
targetName=$1  
#workspace文件 如没有 写 -
workspace=$2
#ipa文件名
ipaName=$3
#临时目录
tempPath=$4

ipaFileName=${tempPath}/$ipaName.ipa

# 创建 文件夹
payloadPath=${tempPath}/Payload
buildPath=${tempPath}/build
appFileFullPath=${buildPath}/Build/Products/Release-iphoneos/${targetName}.app

rm -rf ${payloadPath} ${buildPath}
mkdir -p ${payloadPath} ${buildPath}

if [ ${workspace} = "-" ]
then
   echo 'going to JD'
   xcodebuild -scheme ${targetName} -derivedDataPath  ${buildPath} -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
else
   echo 'going to workspace'
 xcodebuild -workspace ${workspace} -scheme ${targetName} -sdk iphoneos -derivedDataPath  ${buildPath} -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
fi

cp -r ${appFileFullPath} ${payloadPath}

# 打包并生成 .ipa 文件
cd ${tempPath}
zip -q -r ${ipaFileName} Payload
cd -
