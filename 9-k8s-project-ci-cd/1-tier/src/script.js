// Blog Application JavaScript

class BlogApp {
    constructor() {
        this.posts = this.loadPosts();
        this.init();
    }

    init() {
        this.loadInitialPosts();
        this.setupEventListeners();
        this.displayPosts();
    }

    loadInitialPosts() {
        if (this.posts.length === 0) {
            this.posts = [
                {
                    id: 1,
                    title: "Getting Started with Kubernetes",
                    category: "kubernetes",
                    content: "Kubernetes is a powerful container orchestration platform that helps you manage containerized applications at scale. In this post, we'll explore the basics of Kubernetes and how to get started with your first deployment.",
                    author: "DevOps Engineer",
                    date: new Date().toLocaleDateString(),
                    timestamp: Date.now()
                },
                {
                    id: 2,
                    title: "Docker Best Practices",
                    category: "docker",
                    content: "Docker has revolutionized how we build and deploy applications. Here are some best practices for writing efficient Dockerfiles, managing images, and optimizing container performance.",
                    author: "Container Expert",
                    date: new Date().toLocaleDateString(),
                    timestamp: Date.now() - 86400000
                },
                {
                    id: 3,
                    title: "CI/CD Pipeline with GitOps",
                    category: "devops",
                    content: "GitOps is a modern approach to continuous deployment that uses Git as the single source of truth. Learn how to implement GitOps with ArgoCD and automate your deployment pipeline.",
                    author: "DevOps Architect",
                    date: new Date().toLocaleDateString(),
                    timestamp: Date.now() - 172800000
                },
                {
                    id: 4,
                    title: "Modern JavaScript ES6+ Features",
                    category: "javascript",
                    content: "JavaScript has evolved significantly with ES6 and beyond. Explore modern features like arrow functions, destructuring, async/await, and modules that make JavaScript development more efficient.",
                    author: "Frontend Developer",
                    date: new Date().toLocaleDateString(),
                    timestamp: Date.now() - 259200000
                }
            ];
            this.savePosts();
        }
    }

    setupEventListeners() {
        // Add post form submission
        document.getElementById('addPostForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.addPost();
        });

        // Search functionality
        document.getElementById('searchInput').addEventListener('input', () => {
            this.searchPosts();
        });

        // Category filter
        document.getElementById('categoryFilter').addEventListener('change', () => {
            this.filterByCategory();
        });

        // Smooth scrolling for navigation
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            });
        });
    }

    loadPosts() {
        const saved = localStorage.getItem('blogPosts');
        return saved ? JSON.parse(saved) : [];
    }

    savePosts() {
        localStorage.setItem('blogPosts', JSON.stringify(this.posts));
    }

    displayPosts(postsToShow = this.posts) {
        const blogGrid = document.getElementById('blogPosts');
        
        if (postsToShow.length === 0) {
            blogGrid.innerHTML = '<p style="text-align: center; color: #666; font-size: 1.2rem;">No posts found.</p>';
            return;
        }

        // Sort posts by timestamp (newest first)
        const sortedPosts = postsToShow.sort((a, b) => b.timestamp - a.timestamp);

        blogGrid.innerHTML = sortedPosts.map(post => `
            <article class="blog-post" data-category="${post.category}">
                <h3>${this.escapeHtml(post.title)}</h3>
                <span class="category">${post.category.toUpperCase()}</span>
                <div class="content">${this.escapeHtml(post.content)}</div>
                <div class="meta">
                    <span>By ${this.escapeHtml(post.author)} • ${post.date}</span>
                    <button class="delete-btn" onclick="blogApp.deletePost(${post.id})">Delete</button>
                </div>
            </article>
        `).join('');

        // Add animation to posts
        this.animatePosts();
    }

    animatePosts() {
        const posts = document.querySelectorAll('.blog-post');
        posts.forEach((post, index) => {
            post.style.opacity = '0';
            post.style.transform = 'translateY(20px)';
            setTimeout(() => {
                post.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
                post.style.opacity = '1';
                post.style.transform = 'translateY(0)';
            }, index * 100);
        });
    }

    addPost() {
        const title = document.getElementById('postTitle').value.trim();
        const category = document.getElementById('postCategory').value;
        const content = document.getElementById('postContent').value.trim();
        const author = document.getElementById('postAuthor').value.trim();

        if (!title || !category || !content || !author) {
            alert('Please fill in all fields');
            return;
        }

        const newPost = {
            id: Date.now(),
            title,
            category,
            content,
            author,
            date: new Date().toLocaleDateString(),
            timestamp: Date.now()
        };

        this.posts.push(newPost);
        this.savePosts();
        this.displayPosts();
        this.closeAddPostForm();
        
        // Show success message
        this.showNotification('Post added successfully!', 'success');
        
        // Reset form
        document.getElementById('addPostForm').reset();
    }

    deletePost(id) {
        if (confirm('Are you sure you want to delete this post?')) {
            this.posts = this.posts.filter(post => post.id !== id);
            this.savePosts();
            this.displayPosts();
            this.showNotification('Post deleted successfully!', 'success');
        }
    }

    searchPosts() {
        const searchTerm = document.getElementById('searchInput').value.toLowerCase();
        const categoryFilter = document.getElementById('categoryFilter').value;
        
        let filteredPosts = this.posts.filter(post => {
            const matchesSearch = post.title.toLowerCase().includes(searchTerm) ||
                                post.content.toLowerCase().includes(searchTerm) ||
                                post.author.toLowerCase().includes(searchTerm);
            
            const matchesCategory = !categoryFilter || post.category === categoryFilter;
            
            return matchesSearch && matchesCategory;
        });

        this.displayPosts(filteredPosts);
    }

    filterByCategory() {
        this.searchPosts(); // Reuse search logic with category filter
    }

    showAddPostForm() {
        document.getElementById('addPostModal').style.display = 'block';
        document.body.style.overflow = 'hidden';
    }

    closeAddPostForm() {
        document.getElementById('addPostModal').style.display = 'none';
        document.body.style.overflow = 'auto';
    }

    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        
        // Style the notification
        Object.assign(notification.style, {
            position: 'fixed',
            top: '20px',
            right: '20px',
            padding: '15px 20px',
            borderRadius: '5px',
            color: 'white',
            fontWeight: 'bold',
            zIndex: '3000',
            transform: 'translateX(100%)',
            transition: 'transform 0.3s ease',
            backgroundColor: type === 'success' ? '#27ae60' : '#3498db'
        });

        document.body.appendChild(notification);

        // Animate in
        setTimeout(() => {
            notification.style.transform = 'translateX(0)';
        }, 100);

        // Remove after 3 seconds
        setTimeout(() => {
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 300);
        }, 3000);
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // Export data functionality
    exportPosts() {
        const dataStr = JSON.stringify(this.posts, null, 2);
        const dataBlob = new Blob([dataStr], {type: 'application/json'});
        const url = URL.createObjectURL(dataBlob);
        
        const link = document.createElement('a');
        link.href = url;
        link.download = 'blog-posts.json';
        link.click();
        
        URL.revokeObjectURL(url);
    }

    // Import data functionality
    importPosts(event) {
        const file = event.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const importedPosts = JSON.parse(e.target.result);
                if (Array.isArray(importedPosts)) {
                    this.posts = importedPosts;
                    this.savePosts();
                    this.displayPosts();
                    this.showNotification('Posts imported successfully!', 'success');
                }
            } catch (error) {
                this.showNotification('Error importing posts. Please check the file format.', 'error');
            }
        };
        reader.readAsText(file);
    }
}

// Global functions for HTML onclick events
function loadPosts() {
    document.getElementById('blogPosts').scrollIntoView({
        behavior: 'smooth'
    });
}

function showAddPostForm() {
    blogApp.showAddPostForm();
}

function closeAddPostForm() {
    blogApp.closeAddPostForm();
}

function searchPosts() {
    blogApp.searchPosts();
}

function filterByCategory() {
    blogApp.filterByCategory();
}

// Initialize the blog app when DOM is loaded
let blogApp;
document.addEventListener('DOMContentLoaded', () => {
    blogApp = new BlogApp();
    
    // Add some interactive features
    console.log('🚀 Blog App Loaded Successfully!');
    console.log('📝 Total Posts:', blogApp.posts.length);
    
    // Add keyboard shortcuts
    document.addEventListener('keydown', (e) => {
        // Ctrl/Cmd + K to focus search
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            document.getElementById('searchInput').focus();
        }
        
        // Escape to close modal
        if (e.key === 'Escape') {
            blogApp.closeAddPostForm();
        }
    });
});

// Close modal when clicking outside
window.addEventListener('click', (e) => {
    const modal = document.getElementById('addPostModal');
    if (e.target === modal) {
        blogApp.closeAddPostForm();
    }
});