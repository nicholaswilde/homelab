# recipes-rag

LLM RAG service powered by Ollama, serving [Nicholas Wilde's Recipes Repository](https://github.com/nicholaswilde/recipes).

## 🛠️ Details & Architecture

- **Proxmox Node:** `pve03`
- **LXC ID:** `136`
- **Hostname:** `recipes-rag`
- **IP Address:** `192.168.1.122`
- **Hardware Allocation:** 4 Cores, 8 GiB RAM, 2 GiB Swap, 32 GiB Disk (`local-lvm`)
- **OS:** Debian 13 (Trixie)

### Stack

1. **Ollama Service** (`:11434`):
   - **Generation LLM:** `qwen2.5:3b` (fast CPU inference, strong structured recipe reasoning).
   - **Embedding Model:** `nomic-embed-text` (8k context window, embeds full recipe files).
2. **Open WebUI Service** (`:8080`):
   - Web chat UI accessible at [http://192.168.1.122:8080](http://192.168.1.122:8080).
   - Configured with Ollama backend and native RAG knowledge embedding.
3. **Recipes RAG CLI & Vector DB**:
   - Repository cloned to `/opt/recipes`.
   - SQLite vector store in `/opt/recipes-rag/recipes.db`.
   - Automated nightly sync via `recipes-rag-sync.timer` and `recipes-rag-sync.service`.

## 🚀 CLI Usage

SSH into the container or run directly:

```bash
# Query the LLM with recipe context (RAG)
ssh recipes-rag recipes-rag query "What quick pasta recipes can I make with mushrooms and olive oil?"

# Semantic search without LLM generation
ssh recipes-rag recipes-rag search "tahini chickpeas"

# Sync latest changes from recipes git repo and update embeddings
ssh recipes-rag recipes-rag sync
```

## 🌐 Web Interface

Visit [http://192.168.1.122:8080](http://192.168.1.122:8080) to interact via Open WebUI.
