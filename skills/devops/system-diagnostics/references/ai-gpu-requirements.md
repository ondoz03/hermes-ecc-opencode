# AI Workload GPU Requirements

Quick reference for GPU VRAM needs by AI workload type. Useful when a user asks "what GPU do I need for AI?" or "can my GPU run X model?"

## VRAM Requirements by Workload

| Workload | Min VRAM | Recommended VRAM | Example GPUs |
|----------|----------|------------------|--------------|
| **LLM tiny** (Qwen 2.5 1.5B, Gemma 2B) — quantized (Q4) | 2 GB | 4 GB | GTX 950-1060 |
| **LLM small** (Llama 3.1 8B, Mistral 7B, Qwen 7B) — quantized (Q4) | 6 GB | 8-12 GB | RTX 2060S, RTX 3060 |
| **LLM medium** (Llama 3 70B) — quantized (Q4_K_M) | 8 GB (offloaded partially) | 24-48 GB | RTX 3090, 2× RTX 3090 |
| **Stable Diffusion XL** | 4 GB | 8-12 GB | RTX 3060 12GB, RTX 3070 |
| **Whisper (speech-to-text)** | 2 GB | 4 GB | Almost any GPU |
| **Fine-tuning LoRA** (7B model) | 12 GB | 24 GB | RTX 3090, A5000 |
| **Fine-tuning QLoRA** (7B model) | 6 GB | 12 GB | RTX 3060 12GB |
| **Training from scratch** | 24 GB+ | 80 GB (A100/H100) | A100, H100 |
| **Coding AI via API** (e.g., Hermes, Copilot, Codex) | **0 GB** | N/A | No GPU needed |

## Recommended Used GPUs (Indonesian Market, 2026)

| GPU | VRAM | Second Price (IDR) | Best For |
|-----|------|-------------------|----------|
| **RTX 3060** | 12 GB | Rp 2.000.000 - 2.800.000 | 🏆 Best value: LLM 7B Q4, SDXL, QLoRA |
| **RTX 2060 Super** | 8 GB | Rp 1.500.000 - 2.000.000 | Good for LLM 7B Q4, SD 1.5 |
| **RTX 3070** | 8 GB | Rp 2.500.000 - 3.000.000 | Faster than 3060 but same VRAM |
| **RTX 3090** | 24 GB | Rp 6.000.000 - 8.000.000 | 70B models, fine-tuning |
| **GTX 1060** | 6 GB | Rp 500.000 - 700.000 | Budget: small LLMs, SD 1.5 |
| **RTX 3060 Ti** | 8 GB | Rp 2.200.000 - 2.800.000 | Gaming + small AI |

## Shopping Tips (Second GPU)

- Search links: [Tokopedia](https://www.tokopedia.com/search?st=used&q=rtx+3060+12gb), [Shopee](https://shopee.co.id/search?keyword=rtx+3060+12gb+bekas)
- Prefer **store warranty** (garansi toko) over personal warranty
- Ask for **real photos** (not stock NVIDIA images)
- Request **GPU-Z screenshot** or **Furmark benchmark**
- Check seller rating: minimum 4.5⭐
- Avoid "PO" (pre-order) listings for used GPUs
- Typical price negotiation: 5-10% below listed price is reasonable

## Running LLMs Locally on Consumer GPUs

### llama.cpp (best for NVIDIA with limited VRAM)

```bash
# Install
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp && make -j

# Run a Q4_K_M 7B model on 6GB+
./llama-cli -m model-q4_k_m.gguf -n 512 -ngl 35

# Key flags:
#   -ngl N: offload N layers to GPU (use all VRAM, leave ~1GB for system)
#   -t N:   thread count (usually #cores)
#   -c N:   context size (2048-8192, smaller = less VRAM)
```

### Ollama (user-friendly)

```bash
# Install
curl -fsSL https://ollama.com/install.sh | sh

# Run a model (auto GPU acceleration)
ollama run llama3.2:3b    # 3B model, ~2GB VRAM
ollama run qwen2.5:7b     # 7B model, ~6GB VRAM
```

### Hermes + Local Models

Hermes can use local LLMs through:
- **llama.cpp** server: `./llama-server -m model.gguf --port 8080`
- **Ollama**: `ollama serve` (runs on port 11434 by default)
- Configure in `~/.hermes/config.yaml` → `model.provider` = custom endpoint

## CUDA / Driver Notes

- **NVIDIA driver 580+** supports CUDA 13.0
- GTX 900 series (Maxwell) is CUDA 5.0/6.0 — runs most LLM tools but slower than newer arch
- RTX 3000+ series (Ampere) has better tensor core performance
- For llama.cpp: use `make -j LLAMA_CUDA=1` for CUDA acceleration
