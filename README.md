# PyBOMBS mirror site builder

## Usage

```
./010-retrieve-urls-from-recipes.sh
./020-fetch.sh
./030-replace-recipes.sh
```

You can add ignored urls into `ignore.urls`.

And you can define custom upstreams according to your network condition into `pre-replace-upstream.urls` to gain better speed.


## 010-retrieve-urls-from-recipes.sh

 - git clone or update `gr-recipes` and `gr-etcetera` from upstream into `recipes-origin` directory.
 - Copy `recipes-origin` to `recipes`
 - Patching recipes in `recipes` directory with custom urls from `pre-replace-upstream.urls`
 - Generate `recipes-origin.urls` list from `recipes` directory. In fact, it greps all git/svn/wget urls.
 - Remove `ignore.urls` from `recipes-origin.urls`

## 020-fetch.sh

 Fetch repos one by one from `recipes-origin.urls`.

 You have to change the following two args:

 - `PYBOMBS_MIRROR_ROOT_DIR`: your working dir
 - `PYBOMBS_MIRROR_BASE_URL`: Base URL of your mirror site.

 You can also set `DRY_RUN=true` to get a test drive without actually fetching data.

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

## 030-replace-recipes.sh

 Replace URLs in `recipes/` directory using `recipes-mirror-replacement.urls`, then you can publish this directory to your users.


## Mirror Usage


## TODO

 - [ ] SVN fetch method
 - [ ] remove `PYBOMBS_MIRROR_ROOT_DIR`
 - [ ] add mirror usage

