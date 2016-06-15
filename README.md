# PyBOMBS mirror site builder

[![Build Status](https://travis-ci.org/scateu/pybombs-mirror.svg?branch=master)](https://travis-ci.org/scateu/pybombs-mirror)

## As Mirror Maintainer

```bash
sudo apt-get install fcgiwrap nginx git svn wget

./10-retrieve-urls-from-recipes.sh
./20-fetch.sh

# Or test drive without actually fetching
# DRY_RUN=true ./20-fetch.sh

export PYBOMBS_MIRROR_BASE_URL="http://yoursite.example.com/pybombs"
./30-replace-recipes.sh

cp ./40-nginx.conf /etc/nginx/sites-available/default
sudo /etc/init.d/nginx restart

sudo mkdir /pybombs
sudo gpasswd -a yourid www-data  # then logout and in
sudo chown www-data:www-data /pybombs
./50-deploy.sh
```

 - `recipe-repos.urls` Recipes repos to be fetched.
 - *(optional)* `ignore.urls` defines urls that will be ignored. Users of these URLs will be passed through upstream.
 - *(optional)* `pre-replace-upstream.urls` defines custom upstreams replacement. In order to gain better syncing speed according to your network condition.

## As Mirror User

```bash
rm -rf ~/.pybombs
pybombs recipes add gr-recipes git+http://yoursite.example.com/pybombs/git/gr-recipes.git 
pybombs recipes add gr-etcetera git+http://yoursite.example.com/pybombs/git/gr-etcetera.git 
mkdir gnuradio-prefix
cd gnuradio-prefix
pybombs prefix init
pybombs install gnuradio
. ./setup_env.sh
gnuradio-companion
```
### PyBOMBS Update issue

Unfortunately, PyBOMBS only support git as remote repo. Your *patched* recipe repos will make a complex git tree. So we don't want to mess up with a lot of git-cherry-pick git-merge or something.

For now, every time we fetch recipes from upstream, we drop our previously patched commits, generate a new repo. Thus user need to do a refresh `git clone`, because the mirror recipe git repo we generated doesn't have a continous git tree.

As a result, users cannot use `pybombs recipes update` directly.

Instead, users can:

```
pybombs recipes remove gr-etcetera
pybombs recipes remove gr-recipes

pybombs recipes add gr-recipes git+http://yoursite.example.com/pybombs/git/gr-recipes.git 
pybombs recipes add gr-etcetera git+http://yoursite.example.com/pybombs/git/gr-etcetera.git 
```

I think using a local directory is another option, such as:

```bash
git clone --depth=1 http://yoursite.example.com/pybombs/git/gr-recipes.git /path/to/your/git/cache
pybombs recipes add gr-recipes /path/to/your/git/cache

# Updating
rm -rf /path/to/your/git/cache
git clone --depth=1 http://yoursite.example.com/pybombs/git/gr-recipes.git /path/to/your/git/cache
```

Maybe there exists another git trick to help me solve this. sigh..

See also: <http://lists.gnu.org/archive/html/discuss-gnuradio/2016-06/msg00170.html>

# Technical Details

## 10-retrieve-urls-from-recipes.sh

 - git clone or update repos in `recipe-repos.urls` from upstream into `recipes-origin` directory.
 - Copy `recipes-origin` to `recipes`
 - Patching recipes in `recipes` directory with custom urls from `pre-replace-upstream.urls`
 - Generate `recipes-origin.urls` list from `recipes` directory. In fact, it greps all git/svn/wget urls.
 - Remove `ignore.urls` from `recipes-origin.urls`

## 20-fetch.sh

 Fetch repos one by one from `recipes-origin.urls`.

 You can also set `DRY_RUN=true` to get a test drive without actually fetching data.

```
$ DRY_RUN=true ./20-fetch.sh
```

 - Git: All git repos are cloned with `--mirror` argument into `git/` subdirectory.
 - Wget: All wget URLs are fetch into `wget/` subdirectory with 3 max tries. Files are stored without directory hierarchy.
 - SVN: All svn repos are cloned into `svn/` subdirectory.

 - Failure: Any failure will be logged in `failed.log`.

**Output**

 This script will generate a `recipes-mirror-replacement.urls` list containing:

    <ORIGIN_PYBOMBS_URL>  <MIRROR_PYBOMBS_URL>

## 30-replace-recipes.sh

 Replace URLs in `recipes/` directory using `recipes-mirror-replacement.urls`, then you can publish this directory to your users.


## Build a PyBOMBS totally from upstream PyBOMBS mirror

```
wget http://mirrors.tuna.tsinghua.edu.cn/pybombs/recipes-mirror-replacement.urls -O pre-replace-upstream.urls
```

It's very convenient to choose a upstream mirror site with stable network speed.

## Change a URL to another URL while your mirror site don't want to fetch it

1. Add that URL replacement pair into `pre-replace-upstream.urls`
2. Add the latter URL into `ignore.urls`

For example:

```bash
echo "wget+https://download.qt.io/archive/qt/4.6/qt-everywhere-opensource-src-4.6.2.tar.gz  wget+http://mirrors.tuna.tsinghua.edu.cn/qt/archive/qt/4.6/qt-everywhere-opensource-src-4.6.2.tar.gz" >> pre-replace-upstream.urls
echo "wget+http://mirrors.tuna.tsinghua.edu.cn/qt/archive/qt/4.6/qt-everywhere-opensource-src-4.6.2.tar.gz" >> ignore.urls
```

## TODO

 - [ ] SVN fetch method
 - [X] remove `PYBOMBS_MIRROR_ROOT_DIR`
 - [X] add mirror usage
 - [X] auto deploy: gr-recipes and gr-etcetera automatically moved to /pybombs/git/
 - [X] add travis-ci configuration
 - [X] add support for multi repos.
