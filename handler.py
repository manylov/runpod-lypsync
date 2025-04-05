import runpod
from omegaconf import OmegaConf
from pathlib import Path
from scripts.inference import main
import argparse

CONFIG_PATH = Path("configs/unet/stage2.yaml")
CHECKPOINT_PATH = Path("checkpoints/latentsync_unet.pt")

class LatentSyncRunner:
    def __init__(self):
        self.config = OmegaConf.load(CONFIG_PATH)

    def create_args(
        self, 
        video_path: str, 
        audio_path: str, 
        output_path: str, 
        inference_steps: int = 20, 
        guidance_scale: float = 1.5, 
        seed: int = 1247
    ) -> argparse.Namespace:
        parser = argparse.ArgumentParser()
        parser.add_argument("--inference_ckpt_path", type=str, required=True)
        parser.add_argument("--video_path", type=str, required=True)
        parser.add_argument("--audio_path", type=str, required=True)
        parser.add_argument("--video_out_path", type=str, required=True)
        parser.add_argument("--inference_steps", type=int, default=20)
        parser.add_argument("--guidance_scale", type=float, default=1.0)
        parser.add_argument("--seed", type=int, default=1247)

        return parser.parse_args(
            [
                "--inference_ckpt_path",
                CHECKPOINT_PATH.absolute().as_posix(),
                "--video_path",
                video_path,
                "--audio_path",
                audio_path,
                "--video_out_path",
                output_path,
                "--inference_steps",
                str(inference_steps),
                "--guidance_scale",
                str(guidance_scale),
                "--seed",
                str(seed),
            ]
        )

    def process_video(self, job):
        try:
            # Extract input parameters
            input_video = job["input"]["video"]
            input_audio = job["input"]["audio"]
            guidance_scale = job["input"].get("guidance_scale", 1.5)
            inference_steps = job["input"].get("inference_steps", 20)
            seed = job["input"].get("seed", 1247)
            
            # Create output directory
            output_dir = Path("./temp")
            output_dir.mkdir(parents=True, exist_ok=True)

            # Convert paths to absolute Path objects
            video_path = Path(input_video).absolute().as_posix()
            audio_path = Path(input_audio).absolute().as_posix()
            output_path = str(output_dir / f"output_{seed}.mp4")

            # Update config with run parameters
            self.config["run"].update({
                "guidance_scale": guidance_scale,
                "inference_steps": inference_steps,
            })

            # Create args for inference
            args = self.create_args(
                video_path=video_path,
                audio_path=audio_path,
                output_path=output_path,
                inference_steps=inference_steps,
                guidance_scale=guidance_scale,
                seed=seed
            )

            # Run inference
            main(config=self.config, args=args)
            
            return {"output_path": output_path}
            
        except Exception as e:
            return {"error": str(e)}

# Initialize the runner
runner = LatentSyncRunner()

def handler(job):
    """
    RunPod handler function
    """
    return runner.process_video(job)

if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
