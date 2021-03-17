deploy:
	docker run --rm -it \
	-v $$(pwd):/garbonzo \
	-v ~/.kube/config:/root/.kube/config \
	-v ~/.gnupg:/root/.gnupg \
	-w /garbonzo \
	praqma/helmsman:v3.6.6 \
	helmsman $(options) -show-diff --apply -f helmsman_dsf.yml
