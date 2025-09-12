import os
import subprocess
import tempfile
import bittensor as bt


def verify(proof_path, public_inputs_path):
    """
    Verify a zero-knowledge proof using the BB verifier.

    Args:
        proof_path (str): Path to the proof file
        public_inputs_path (str): Path to the public inputs file

    Returns:
        bool: True if verification succeeds, False otherwise
    """
    if not os.path.exists(proof_path):
        bt.logging.error(f"Proof file not found: {proof_path}")
        return False

    if not os.path.exists(public_inputs_path):
        bt.logging.error(f"Public inputs file not found: {public_inputs_path}")
        return False

    vk_path = os.path.join(os.path.dirname(__file__), "circuits", "vk", "vk")
    if not os.path.exists(vk_path):
        bt.logging.error(f"Verification key file not found: {vk_path}")
        return False

    try:
        result = subprocess.run(
            ["bb", "verify", "-k", vk_path, "-p", proof_path, "-i", public_inputs_path],
            capture_output=True,
            text=True,
            timeout=60,
        )

        if result.returncode == 0:
            bt.logging.info("Proof verification successful")
            return True
        else:
            bt.logging.error(f"Proof verification failed: {result.stderr}")
            return False

    except subprocess.TimeoutExpired:
        bt.logging.error("Proof verification timed out")
        return False
    except Exception as e:
        bt.logging.error(f"Error during proof verification: {str(e)}")
        return False


def verify_proof_data(proof_data, public_inputs_data):
    """
    Verify a zero-knowledge proof using raw data instead of file paths.

    Args:
        proof_data (bytes): Raw proof data
        public_inputs_data (bytes): Raw public inputs data

    Returns:
        bool: True if verification succeeds, False otherwise
    """
    try:
        with tempfile.TemporaryDirectory() as temp_dir:
            proof_path = os.path.join(temp_dir, "proof")
            public_inputs_path = os.path.join(temp_dir, "public_inputs")

            with open(proof_path, "wb") as f:
                f.write(proof_data)
            with open(public_inputs_path, "wb") as f:
                f.write(public_inputs_data)

            return verify(proof_path, public_inputs_path)

    except Exception as e:
        bt.logging.error(f"Error during proof verification with raw data: {str(e)}")
        return False
