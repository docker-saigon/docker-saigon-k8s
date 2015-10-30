# Docker Saigon - Intro to Kubernetes

Linux containers provide the ability to reliably deploy thousands of application instances in seconds, but how do we manage it all? The answer is CoreOS and Kubernetes. This talk will help attendees wrap their minds around complex topics such as distributed configuration management, service discovery, and application scheduling at scale.

Follow the [setup-DigitalOcean](setup-DigitalOcean) to quickly create the demo environment on Digital Ocean

This demo script is a fork of [Kelsey Hightower demonstration at yapc-asia](https://github.com/kelseyhightower/yapc-asia-2015)

[YouTube video of timestamp where Kelsey's demo starts](https://www.youtube.com/watch?v=-8aUxpVrD40&feature=youtu.be&t=972)

Demo confirmed working with k8s v1.0.4

The slides for this talk are available on [slides.google.com](https://goo.gl/E4QRQu)

## Notes

1. `cloud-init-master.yaml` was changed to include `--service-node-port-range` flag
1. If you get "SEGV" errors in the logs (`journalctl -f kube-<service>`), test if binary was curled successfully, curl again manually to fix (took me too long to figure this out)
