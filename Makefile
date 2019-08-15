tarball:
	git archive --format=tar HEAD | gzip > adriana.tar.gz

.PHONY: tarball
