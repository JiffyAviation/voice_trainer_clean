import tkinter as tk
from tkinter import ttk, messagebox
import serial
import serial.tools.list_ports
import time

class GRBLTesterApp:
    def __init__(self, master):
        self.master = master
        master.title("GRBL Tester")

        self.serial_port = None
        self.grbl_connected = False

        self.create_widgets()

    def create_widgets(self):
        # Frame for Serial Connection
        serial_frame = ttk.LabelFrame(self.master, text="Serial Connection")
        serial_frame.pack(padx=10, pady=10, fill="x")

        self.port_label = ttk.Label(serial_frame, text="COM Port:")
        self.port_label.grid(row=0, column=0, padx=5, pady=5, sticky="w")

        self.port_combo = ttk.Combobox(serial_frame, width=20)
        self.port_combo.grid(row=0, column=1, padx=5, pady=5, sticky="ew")
        self.port_combo.bind('<KeyRelease>', self.on_port_entry)
        self.populate_ports()

        self.refresh_button = ttk.Button(serial_frame, text="Refresh", command=self.populate_ports)
        self.refresh_button.grid(row=0, column=2, padx=5, pady=5)

        self.connect_button = ttk.Button(serial_frame, text="Connect", command=self.connect_grbl)
        self.connect_button.grid(row=0, column=3, padx=5, pady=5)

        self.disconnect_button = ttk.Button(serial_frame, text="Disconnect", command=self.disconnect_grbl, state=tk.DISABLED)
        self.disconnect_button.grid(row=0, column=4, padx=5, pady=5)

        # Add status and board info labels
        self.status_label = ttk.Label(serial_frame, text="Status: Not Connected", foreground="red")
        self.status_label.grid(row=1, column=0, columnspan=2, padx=5, pady=5, sticky="w")

        self.board_info_label = ttk.Label(serial_frame, text="Board Info: None", wraplength=400)
        self.board_info_label.grid(row=2, column=0, columnspan=5, padx=5, pady=5, sticky="w")

        # Frame for Switch Lights
        lights_frame = ttk.LabelFrame(self.master, text="Switch Status Lights")
        lights_frame.pack(padx=10, pady=10, fill="x")

        # X Endstop Light
        ttk.Label(lights_frame, text="X Endstop:").grid(row=0, column=0, padx=10, pady=10)
        self.x_light = tk.Canvas(lights_frame, width=30, height=30, bg='white')
        self.x_light.grid(row=0, column=1, padx=10, pady=10)
        self.x_circle = self.x_light.create_oval(5, 5, 25, 25, fill='red', outline='black')

        # Y Endstop Light
        ttk.Label(lights_frame, text="Y Endstop:").grid(row=0, column=2, padx=10, pady=10)
        self.y_light = tk.Canvas(lights_frame, width=30, height=30, bg='white')
        self.y_light.grid(row=0, column=3, padx=10, pady=10)
        self.y_circle = self.y_light.create_oval(5, 5, 25, 25, fill='red', outline='black')

        # Case Switch Light
        ttk.Label(lights_frame, text="Case Switch:").grid(row=0, column=4, padx=10, pady=10)
        self.case_light = tk.Canvas(lights_frame, width=30, height=30, bg='white')
        self.case_light.grid(row=0, column=5, padx=10, pady=10)
        self.case_circle = self.case_light.create_oval(5, 5, 25, 25, fill='red', outline='black')

        # Frame for Motor Control
        motor_frame = ttk.LabelFrame(self.master, text="Motor Control")
        motor_frame.pack(padx=10, pady=10, fill="x")

        ttk.Label(motor_frame, text="X Axis:").grid(row=0, column=0, padx=5, pady=5)
        self.x_dir_var = tk.StringVar(value="Positive")
        self.x_dir_pos = ttk.Radiobutton(motor_frame, text="Positive", variable=self.x_dir_var, value="Positive")
        self.x_dir_pos.grid(row=0, column=1, padx=5, pady=5, sticky="w")
        self.x_dir_neg = ttk.Radiobutton(motor_frame, text="Negative", variable=self.x_dir_var, value="Negative")
        self.x_dir_neg.grid(row=0, column=2, padx=5, pady=5, sticky="w")
        self.x_move_button = ttk.Button(motor_frame, text="Move X", command=lambda: self.move_motor('X', self.x_dir_var.get()), state=tk.DISABLED)
        self.x_move_button.grid(row=0, column=3, padx=5, pady=5)

        ttk.Label(motor_frame, text="Y Axis:").grid(row=1, column=0, padx=5, pady=5)
        self.y_dir_var = tk.StringVar(value="Positive")
        self.y_dir_pos = ttk.Radiobutton(motor_frame, text="Positive", variable=self.y_dir_var, value="Positive")
        self.y_dir_pos.grid(row=1, column=1, padx=5, pady=5, sticky="w")
        self.y_dir_neg = ttk.Radiobutton(motor_frame, text="Negative", variable=self.y_dir_var, value="Negative")
        self.y_dir_neg.grid(row=1, column=2, padx=5, pady=5, sticky="w")
        self.y_move_button = ttk.Button(motor_frame, text="Move Y", command=lambda: self.move_motor('Y', self.y_dir_var.get()), state=tk.DISABLED)
        self.y_move_button.grid(row=1, column=3, padx=5, pady=5)

        ttk.Label(motor_frame, text="Z Axis:").grid(row=2, column=0, padx=5, pady=5)
        self.z_dir_var = tk.StringVar(value="Positive")
        self.z_dir_pos = ttk.Radiobutton(motor_frame, text="Positive", variable=self.z_dir_var, value="Positive")
        self.z_dir_pos.grid(row=2, column=1, padx=5, pady=5, sticky="w")
        self.z_dir_neg = ttk.Radiobutton(motor_frame, text="Negative", variable=self.z_dir_var, value="Negative")
        self.z_dir_neg.grid(row=2, column=2, padx=5, pady=5, sticky="w")
        self.z_move_button = ttk.Button(motor_frame, text="Move Z", command=lambda: self.move_motor('Z', self.z_dir_var.get()), state=tk.DISABLED)
        self.z_move_button.grid(row=2, column=3, padx=5, pady=5)

        # Frame for Switch Testing
        switch_frame = ttk.LabelFrame(self.master, text="Switch Testing")
        switch_frame.pack(padx=10, pady=10, fill="x")

        self.start_switch_test_button = ttk.Button(switch_frame, text="Start Switch Test", command=self.start_switch_test, state=tk.DISABLED)
        self.start_switch_test_button.pack(padx=5, pady=5)

        self.stop_switch_test_button = ttk.Button(switch_frame, text="Stop Switch Test", command=self.stop_switch_test, state=tk.DISABLED)
        self.stop_switch_test_button.pack(padx=5, pady=5)

        self.switch_test_running = False

    def on_port_entry(self, event):
        """Allow manual entry of COM port"""
        pass

    def populate_ports(self):
        ports = serial.tools.list_ports.comports()
        port_names = [port.device for port in ports]
        
        # Add common COM ports that might not be detected
        common_ports = ['COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8']
        for port in common_ports:
            if port not in port_names:
                port_names.append(port)
        
        self.port_combo['values'] = port_names
        if port_names:
            # Set to COM4 if available, otherwise first port
            if 'COM4' in port_names:
                self.port_combo.set('COM4')
            else:
                self.port_combo.set(port_names[0])

    def update_switch_lights(self, x_triggered, y_triggered, case_triggered):
        """Update the visual switch indicators"""
        # Red = not triggered, Green = triggered
        x_color = 'green' if x_triggered else 'red'
        y_color = 'green' if y_triggered else 'red'
        case_color = 'green' if case_triggered else 'red'
        
        self.x_light.itemconfig(self.x_circle, fill=x_color)
        self.y_light.itemconfig(self.y_circle, fill=y_color)
        self.case_light.itemconfig(self.case_circle, fill=case_color)

    def get_board_info(self):
        """Query GRBL for board information"""
        info = []
        try:
            # Get GRBL version and build info
            version_response = self.send_gcode("$I")
            if version_response:
                info.append(f"Version: {version_response}")
            
            return " | ".join(info) if info else "Info not available"
        except:
            return "Info not available"

    def connect_grbl(self):
        selected_port = self.port_combo.get()
        if not selected_port:
            messagebox.showwarning("No Port", "Please select or enter a COM port.")
            return
            
        try:
            self.serial_port = serial.Serial(selected_port, 115200, timeout=1)
            time.sleep(2)
            self.serial_port.write(b'\r\n\r\n')
            time.sleep(1)
            self.serial_port.flushInput()
            
            # Get board info
            board_info = self.get_board_info()
            
            self.grbl_connected = True
            messagebox.showinfo("Connection", f"Connected to GRBL on {selected_port}")
            self.update_ui_on_connection(board_info)
        except serial.SerialException as e:
            messagebox.showerror("Connection Error", f"Could not connect to {selected_port}: {e}")

    def disconnect_grbl(self):
        if self.serial_port and self.serial_port.is_open:
            self.serial_port.close()
            self.grbl_connected = False
            self.switch_test_running = False
            messagebox.showinfo("Disconnection", "Disconnected from GRBL")
            self.update_ui_on_connection()

    def update_ui_on_connection(self, board_info="None"):
        if self.grbl_connected:
            self.connect_button.config(state=tk.DISABLED)
            self.disconnect_button.config(state=tk.NORMAL)
            self.x_move_button.config(state=tk.NORMAL)
            self.y_move_button.config(state=tk.NORMAL)
            self.z_move_button.config(state=tk.NORMAL)
            self.start_switch_test_button.config(state=tk.NORMAL)
            self.status_label.config(text="Status: Connected", foreground="green")
            self.board_info_label.config(text=f"Board Info: {board_info}")
        else:
            self.connect_button.config(state=tk.NORMAL)
            self.disconnect_button.config(state=tk.DISABLED)
            self.x_move_button.config(state=tk.DISABLED)
            self.y_move_button.config(state=tk.DISABLED)
            self.z_move_button.config(state=tk.DISABLED)
            self.start_switch_test_button.config(state=tk.DISABLED)
            self.stop_switch_test_button.config(state=tk.DISABLED)
            self.status_label.config(text="Status: Not Connected", foreground="red")
            self.board_info_label.config(text="Board Info: None")
            # Reset lights to red when disconnected
            self.update_switch_lights(False, False, False)

    def send_gcode(self, command):
        if self.grbl_connected:
            self.serial_port.write(command.encode() + b'\n')
            response = self.serial_port.readline().decode().strip()
            return response
        return ""

    def move_motor(self, axis, direction):
        if not self.grbl_connected:
            messagebox.showwarning("Not Connected", "Please connect to GRBL first.")
            return

        distance = 10
        if direction == "Negative":
            distance *= -1

        command = f"G91\nG0 {axis}{distance}\nG90"
        self.send_gcode(command)

    def start_switch_test(self):
        if not self.grbl_connected:
            messagebox.showwarning("Not Connected", "Please connect to GRBL first.")
            return

        self.send_gcode("$10=19")
        self.switch_test_running = True
        self.stop_switch_test_button.config(state=tk.NORMAL)
        self.start_switch_test_button.config(state=tk.DISABLED)
        self.check_switches()

    def stop_switch_test(self):
        self.switch_test_running = False
        self.stop_switch_test_button.config(state=tk.DISABLED)
        self.start_switch_test_button.config(state=tk.NORMAL)
        self.send_gcode("$10=3")
        # Reset lights to red when test stops
        self.update_switch_lights(False, False, False)

    def check_switches(self):
        if self.switch_test_running and self.grbl_connected:
            response = self.send_gcode("?")
            if "Lim:" in response:
                lim_start = response.find("Lim:") + len("Lim:")
                lim_end = response.find(">", lim_start)
                if lim_end != -1:
                    lim_status = response[lim_start:lim_end].strip()
                    # For NC switches, '0' means triggered, '1' means not triggered
                    # Assuming order is ZYX, but we only care about YX and case switch
                    if len(lim_status) >= 3:
                        x_triggered = lim_status[2] == '0'  # X switch
                        y_triggered = lim_status[1] == '0'  # Y switch
                        case_triggered = lim_status[0] == '0'  # Case switch (using Z position)
                        
                        self.update_switch_lights(x_triggered, y_triggered, case_triggered)
            
            self.master.after(200, self.check_switches)

if __name__ == "__main__":
    root = tk.Tk()
    app = GRBLTesterApp(root)
    root.mainloop()