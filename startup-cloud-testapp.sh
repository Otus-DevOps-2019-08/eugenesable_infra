 #!/bin/bash
echo "Installing ruby"
sh ./install_ruby.sh
echo "Installing mongodb"
sh ./install_mongodb.sh
echo "Deploying Monolith and start server"
sh ./deploy.sh
