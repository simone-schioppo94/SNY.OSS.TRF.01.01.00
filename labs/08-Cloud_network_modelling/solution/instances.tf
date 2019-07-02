// Two Google Cloud Engine instances

// Web server instance
resource "google_compute_instance" "webserver" {
 name         = "fe-${random_id.random_id.hex}"
 machine_type = "f1-micro"
 zone         = "${var.REGION}-${var.ZONE}"
 tags          = ["ssh","http"]
 provisioner "remote-exec" {
   inline = [
     "sudo apt-get install -y nginx"
   ]

   connection {
    type     = "ssh"
    host     = "${google_compute_instance.webserver.network_interface.0.access_config.0.nat_ip}"
    user     = "${var.VM_USERNAME}"
    private_key = "${file("~/.ssh/id_rsa")}"
  }
 }

 provisioner "file" {
       source      = "config/nginx.conf"
       destination = "/tmp/demo"

    connection {
      type     = "ssh"
      host     = "${google_compute_instance.webserver.network_interface.0.access_config.0.nat_ip}"
      user     = "${var.VM_USERNAME}"
      private_key = "${file("~/.ssh/id_rsa")}"
   }
}

provisioner "remote-exec" {
   inline = [
     "sudo cp /tmp/demo /etc/nginx/sites-available/demo",
     "sudo chmod 644 /etc/nginx/sites-available/demo",
     "sudo rm -f /etc/nginx/sites-enabled/default",
     "sudo ln -s /etc/nginx/sites-available/demo /etc/nginx/sites-enabled/demo",
     "sudo /etc/init.d/nginx restart"
   ]

   connection {
    type     = "ssh"
    host     = "${google_compute_instance.webserver.network_interface.0.access_config.0.nat_ip}"
    user     = "${var.VM_USERNAME}"
    private_key = "${file("~/.ssh/id_rsa")}"
  }
 }


 boot_disk {
   initialize_params {
    image = "${lookup(var.IMAGE,"${var.REGION}-${var.ZONE}")}"
   }
 }

 network_interface {
   subnetwork = "${google_compute_subnetwork.public_subnet.self_link}"

   access_config {
     // Include this section to give the VM an external ip address
   }
 }

  metadata = {
   ssh-keys = "${var.VM_USERNAME}:${file("~/.ssh/id_rsa.pub")}"
 }

  
}

output "webserver-ip" {
    value = "${google_compute_instance.webserver.network_interface.0.access_config.0.nat_ip}"
}



// App server instance
resource "google_compute_instance" "appserver" {
 name         = "be-${random_id.random_id.hex}"
 machine_type = "f1-micro"
 zone         = "${var.REGION}-${var.ZONE}"

 provisioner "remote-exec" {
   inline = [
     "sudo apt-get install -y apache"
   ]

   connection {
    type     = "ssh"
    host     = "${google_compute_instance.webserver.network_interface.0.access_config.0.nat_ip}"
    user     = "${var.VM_USERNAME}"
    private_key = "${file("~/.ssh/id_rsa")}"
  }
 }

 boot_disk {
   initialize_params {
    image = "${lookup(var.IMAGE,"${var.REGION}-${var.ZONE}")}"
   }
 }

 network_interface {
   subnetwork = "${google_compute_subnetwork.private_subnet.self_link}"
 }

  metadata = {
   ssh-keys = "${var.VM_USERNAME}:${file("~/.ssh/id_rsa.pub")}"
 }

  
}
