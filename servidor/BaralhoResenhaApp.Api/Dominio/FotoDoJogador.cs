using System.Security.Cryptography;

namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Selfie do jogador. O app já manda a foto recortada e pequena; ela vive
/// na memória junto com a sala. O id muda a cada foto nova, então o
/// navegador pode guardar a imagem sem medo de mostrar uma antiga.
/// </summary>
public sealed record FotoDoJogador(string Id, byte[] Conteudo, string TipoDeConteudo)
{
    internal const int TamanhoMaximo = 512 * 1024;

    public static FotoDoJogador Criar(byte[] conteudo)
    {
        if (conteudo.Length == 0)
            throw new AcaoNaoPermitidaException("A foto chegou vazia. Tente de novo.");
        if (conteudo.Length > TamanhoMaximo)
            throw new AcaoNaoPermitidaException("A foto ficou grande demais. Tente de novo.");
        var tipo = TipoDe(conteudo)
            ?? throw new AcaoNaoPermitidaException("Envie a foto em JPEG, PNG ou WebP.");
        var id = Convert.ToHexString(RandomNumberGenerator.GetBytes(16)).ToLowerInvariant();
        return new FotoDoJogador(id, conteudo, tipo);
    }

    private static string? TipoDe(byte[] conteudo) => conteudo switch
    {
        [0xFF, 0xD8, 0xFF, ..] => "image/jpeg",
        [0x89, 0x50, 0x4E, 0x47, ..] => "image/png",
        [0x52, 0x49, 0x46, 0x46, _, _, _, _, 0x57, 0x45, 0x42, 0x50, ..] => "image/webp",
        _ => null
    };
}
