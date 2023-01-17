flux bootstrap github \
  --owner=$GITUSER \
  --repository=DevSecOps-Toolbox \
  --path=clusters/mason-dev \
  --personal \
	--branch=main \
	--network-policy=false \
	--components-extra=image-reflector-controller,image-automation-controller
