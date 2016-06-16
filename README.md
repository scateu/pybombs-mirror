# PyBOMBS mirror site builder

[![Build Status](https://travis-ci.org/scateu/pybombs-mirror.svg?branch=master)](https://travis-ci.org/scateu/pybombs-mirror)

## As Mirror Maintainer

```bash
sudo apt-get install fcgiwrap nginx git svn wget

# Or test drive without actually fetching
# DRY_RUN=true ./20-fetch.sh

export PYBOMBS_MIRROR_BASE_URL="http://yoursite.example.com/pybombs"
export DRY_RUN=true 
export PYBOMBS_MIRROR_WORK_DIR=/home/scateu/pybombs-mirror-site

./pybombs-mirror.sh

cp ./nginx.conf /etc/nginx/sites-available/default

sudo /etc/init.d/nginx restart

sudo mkdir /pybombs
sudo gpasswd -a yourid www-data  # then logout and in
sudo chown www-data:www-data /pybombs
```
 - `upstream-recipe-repos.urls` Recipes repos to be fetched.
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

```

10-retrieve-urls-from-recipes....................................................

                                 Upstream recipes
                                       |
                                       | [git clone/update]
                                       v
   upstream-recipe-repos.urls     -->    recipes-origin/
                                       |
                                       | [Copy]
                                       v
                                    _recipes/
                                       |
pre-replace-upstream.urls    ---->     +
                                       | [grep & sed]
                                       v
                                    _recipes/
                                       |
                                       | [grep]
                                       v
                               recipes-origin.urls
                                       |
     ignore.urls             ---->     +
                                       | [sed]
                                       v
                               recipes-origin.urls
                                       |
20-fetch...............................|.........................................
                                       |             +--> svn/
                                       v             |
                                    [Fetch..] -------+--> wget/
                                       |             |
                                +------+------+      +--> git/
                                |             | 
                                V             V 
       _recipes-mirror-replacement.urls     failed.log
(PYBOMBS_MIRROR_BASE_URL as placeholder)
                                |
30-replace-_recipes.............|................................................
                                |
                     [sed] PYBOMBS_MIRROR_BASE_URL -> $PYBOMBS_MIRROR_BASE_URL
                                |
                                v
        recipes-mirror-replacement.urls -- [sed] --> _recipes/
                                                        |
40-deploy...............................................|........................
                                                        | [git commit -am  ]
                                                        | [git clone --bare]
                                                        v
                                                      recipes/
                                                        |
                                                        |
                                                        v
                                                       DONE. 
```


## Build a PyBOMBS totally from upstream PyBOMBS mirror

```
wget http://mirrors.tuna.tsinghua.edu.cn/pybombs/pre-replace-upstream.urls -O 1.urls
wget http://mirrors.tuna.tsinghua.edu.cn/pybombs/recipes-mirror-replacement.urls -O 2.urls
cat 1.urls 2.urls > pre-replace-upstream.urls
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
