import tensorflow as tf
import sys

def inspect_tflite(model_path):
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("=== INPUT DETAILS ===")
    for d in input_details:
        print(f"Name: {d['name']}")
        print(f"Shape: {d['shape']}")
        print(f"Type: {d['dtype']}")
        print(f"Quantization: {d['quantization']}")
        
    print("\n=== OUTPUT DETAILS ===")
    for d in output_details:
        print(f"Name: {d['name']}")
        print(f"Shape: {d['shape']}")
        print(f"Type: {d['dtype']}")
        print(f"Quantization: {d['quantization']}")

if __name__ == "__main__":
    inspect_tflite(sys.argv[1])
