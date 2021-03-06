#!/bin/bash

rm -rf build

mkdir -p build/extension
mkdir -p build/preview
mkdir -p build/server

previewurl=$(grep preview.url build.conf | awk -F= '{print $2}')
serverurl=$(grep server.url build.conf | awk -F= '{print $2}')
printcmd=$(grep print.cmd build.conf | awk -F= '{print $2}')
extversion=$(grep ext.version build.conf | awk -F= '{print $2}')

cat > build/extension/print.js <<END
var preview = "$previewurl";
END
cat > build/preview/open.js <<END
var server = "$serverurl";
var preview = "$previewurl";
END
cat > build/preview/preview.js <<END
var server = "$serverurl";
END
cat > build/server/server.rb <<END
PRINT_CMD = "$printcmd"
END

for f in $(find src -type f ! -name '*.json'); do
	out=$(echo $f | sed 's|src|build|')
	cat $f >> $out
done

baseurl=$(echo $previewurl | sed 's|\(\w\+://[^/]\+/\?\).*|\1|')

cat src/extension/manifest.json | sed > build/extension/manifest.json \
's|\("permissions".*\)\(\s],\)|\1, "'$baseurl'"\2|;'\
's|\(.*\)\("manifest_version".*:.*\)|\1\2\
\1"version": "'$extversion'",|'
