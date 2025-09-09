import subprocess
import json

# Run hyprctl and get JSON output
result = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True)
clients = json.loads(result.stdout)

# Build dictionary: title -> class
client_dict = {client.get("title", ""): client.get("class", "") for client in clients}

print(client_dict)
if client_dict.keys == client_dict.values:
    print("Working")
else:
    print('fail')