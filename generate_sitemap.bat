rem npm install -g sitemap-generator-cli
rem npm install -g replace

call sitemap-generator http://127.0.0.1:3000/
call replace.cmd "http://127.0.0.1:3000/" "https://icedream2linxi.github.io/" sitemap.xml
if exist tt.xml del tt.xml
rename sitemap.xml tt.xml
echo ---> sitemap.xml
echo layout: null>> sitemap.xml
echo --->> sitemap.xml
type tt.xml >> sitemap.xml
if exist tt.xml del tt.xml
