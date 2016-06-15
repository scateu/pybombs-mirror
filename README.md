# PyBOMBS mirror site builder

## TODO

 - [ ] SVN fetch method
 - [X] remove `PYBOMBS_MIRROR_ROOT_DIR`
 - [X] add mirror usage
 - [X] auto deploy: gr-recipes and gr-etcetera automatically moved to /pybombs/git/
 - [X] add travis-ci configuration
 - [X] add support for multi repos.

## As Mirror Maintainer


```bash
sudo apt-get install fcgiwrap nginx git svn wget

./10-retrieve-urls-from-recipes.sh
./20-fetch.sh

export PYBOMBS_MIRROR_BASE_URL="http://yoursite.example.com/pybombs"
./30-replace-recipes.sh

cp ./40-nginx.conf /etc/nginx/sites-available/default
sudo /etc/init.d/nginx restart

sudo mkdir /pybombs
sudo chown www-data:www-data /pybombs
./50-deploy.sh
```

Recipes repos that you'd like to mirror are placed in `recipe-repos.urls`.

You can add ignored urls into `ignore.urls`.

And you can define custom upstreams according to your network condition into `pre-replace-upstream.urls` to gain better speed.

## As Mirror User

```bash
rm -rf ~/.pybombs
pybombs recipes add gr-recipes git+http://localhost/pybombs/git/gr-recipes.git 
pybombs recipes add gr-etcetera git+http://localhost/pybombs/git/gr-etcetera.git 
mkdir gnuradio-prefix
cd gnuradio-prefix
pybombs prefix init
pybombs install gnuradio
. ./setup_env.sh
gnuradio-companion
```

# Technical Details

## 10-retrieve-urls-from-recipes.sh

 - git clone or update repos in `recipe-repos.urls` from upstream into `recipes-origin` directory.
 - Copy `recipes-origin` to `recipes`
 - Patching recipes in `recipes` directory with custom urls from `pre-replace-upstream.urls`
 - Generate `recipes-origin.urls` list from `recipes` directory. In fact, it greps all git/svn/wget urls.
 - Remove `ignore.urls` from `recipes-origin.urls`

## 20-fetch.sh

 Fetch repos one by one from `recipes-origin.urls`.

 You have to change the following two args:

 - `PYBOMBS_MIRROR_ROOT_DIR`: your working dir
 - `PYBOMBS_MIRROR_BASE_URL`: Base URL of your mirror site.

 You can also set `DRY_RUN=true` to get a test drive without actually fetching data.

```
$ DRY_RUN=true ./20-fetch.sh
```

### Git

 All git repos are cloned with `--mirror` argument into `git/` subdirectory.

### Wget

 All wget URLs are fetch into `wget/` subdirectory with 3 max tries. Files are stored without directory hierarchy.

### SVN

 All svn repos are cloned into `svn/` subdirectory.

### Failure

 Any failure will be logged in `failed.log`.

### Output

 Then it will generate a `recipes-mirror-replacement.urls` list:

    <ORIGIN_PYBOMBS_URL>  <MIRROR_PYBOMBS_URL>

## 30-replace-recipes.sh

 Replace URLs in `recipes/` directory using `recipes-mirror-replacement.urls`, then you can publish this directory to your users.



